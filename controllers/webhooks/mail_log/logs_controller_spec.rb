require 'rails_helper'

RSpec.describe Webhooks::MailLog::LogsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { create(:promoter, organization: organization) }
  let(:investor) { create(:investor, organization: organization, promoter: promoter) }
  let(:monthly_cut) do
    create(:monthly_cut,
           year: 2020,
           month: 8,
           cut_day: 31
           )
  end

  let(:valid_attributes) { 
    {
      mail: "test@gmail.com",
      dispatched_event: "Click",
      message: "Clickeado",
      involved: investor,
      timestamp: DateTime.now,
      mail_loggable: monthly_cut
    }
   }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user

    Current.organization = organization
    Current.user = user
  end

  describe "GET #index" do
    it "returns a success response" do
      mail_log = create(:mail_log, valid_attributes)

      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      mail_log = create(:mail_log, valid_attributes)

      get :show, params: {id: mail_log.to_param}
      expect(response).to be_successful
    end
  end

  context "Mailgun events" do
    it "delivered" do
      params = JSON.load(File.new('./lib/specs/mail_logs/mailgun_events/events.json'))['delivered']

      params['event-data']['user-variables']['mail_loggable_type'] = "\"MonthlyCut\""
      params['event-data']['user-variables']['mail_loggable_id'] = monthly_cut.id

      params['event-data']['user-variables']['involved_type'] = "\"Investor\""
      params['event-data']['user-variables']['involved_id'] = investor.id

      post :info, params: params

      expect(response).to be_successful
      expect(JSON.parse(response.body)['data']['dispatched_event']).to eq('delivered')
    end

    it "CLICKED" do
      params = JSON.load(File.new('./lib/specs/mail_logs/mailgun_events/events.json'))['CLICKED']

      params['event-data']['user-variables']['mail_loggable_type'] = 'MonthlyCut'
      params['event-data']['user-variables']['mail_loggable_id'] = monthly_cut.id

      params['event-data']['user-variables']['involved_type'] = 'Investor'
      params['event-data']['user-variables']['involved_id'] = investor.id

      post :info, params: params

      expect(response).to be_successful
      expect(JSON.parse(response.body)['data']['dispatched_event']).to eq('CLICKED')
    end

    it "OPENED" do
      params = JSON.load(File.new('./lib/specs/mail_logs/mailgun_events/events.json'))['OPENED']

      params['event-data']['user-variables']['mail_loggable_type'] = 'MonthlyCut'
      params['event-data']['user-variables']['mail_loggable_id'] = monthly_cut.id

      params['event-data']['user-variables']['involved_type'] = 'Investor'
      params['event-data']['user-variables']['involved_id'] = investor.id

      post :info, params: params

      expect(response).to be_successful
      expect(JSON.parse(response.body)['data']['dispatched_event']).to eq('OPENED')
    end

    it "failed generic" do
      params = JSON.load(File.new('./lib/specs/mail_logs/mailgun_events/events.json'))['failed-2']

      params['event-data']['user-variables']['mail_loggable_type'] = 'MonthlyCut'
      params['event-data']['user-variables']['mail_loggable_id'] = monthly_cut.id

      params['event-data']['user-variables']['involved_type'] = 'Investor'
      params['event-data']['user-variables']['involved_id'] = investor.id

      post :info, params: params

      expect(response).to be_successful
      expect(JSON.parse(response.body)['data']["message"]). to eq(params['event-data']['delivery-status']['message'])
    end
  end
end
