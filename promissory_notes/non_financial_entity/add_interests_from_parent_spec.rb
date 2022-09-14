require 'rails_helper'

describe 'Simple', :acceptance_spec, slow: true do
  let(:organization) do
    organization = create(:organization, :default_configuration)
    organization.configuration['day_count_algorithm'] = 'natural'
    organization.configuration['fixed_retention'] = true
    organization.configuration['add_interests_from_parent_by_transaction'] = false
    organization.save!
    organization
  end
  let(:society) do
    society = build(:organization_society, organization: organization)
    society.is_financial_entity = false
    society.save!
    society
  end
  let(:user) { create(:user, organizations: [organization]) }
  let(:promoter) do
    create(:promoter, organization: organization, updated_by: user, created_by: user)
  end
  let(:investor) do
    create(:investor, organization: organization, promoter: promoter, updated_by: user, created_by: user)
  end
  let(:parent) do
    create(:promissory_note,
           type_of: 'capitalization',
           initial_amount: 2_000_000,
           interest_rate: 18,
           tax_percentage: 0,
           iva_percentage: 16,
           cut_day: 31,
           capitalization_periodicity: 2,
           monthly_periodicity: nil,
           start_date: Date.new(2021, 9, 25),
           end_date: Date.new(2022, 3, 25),
           organization: organization,
           society: society,
           investor: investor,
           promoter: promoter,
           created_by: user,
           updated_by: user,
           configuration: organization.configuration.merge!(
             day_count_algorithm: 'natural',
             fiscal_year_days: 360,
             start_date_excluded: true,
             event_date_included: false,
             end_date_included: false,
             fixed_retention: true,
             payment_on_subscription_date: true,
             pay_on_expiration: true,
             retention_on_payment: true,
             n_days: 30
           ))
  end

  before(:each) do
    Current.organization = organization
    Current.user = user
  end

  context 'Renew' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: parent.theoretical_balance(Date.new(2022, 3, 25)),
               interest_rate: 18,
               tax_percentage: 0,
               iva_percentage: 16,
               parent_id: parent.id,
               cut_day: 31,
               capitalization_periodicity: 2,
               start_date: Date.new(2022, 3, 25),
               end_date: Date.new(2023, 3, 25),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 add_interests_from_parent: true,
                 event_date_included: false,
                 end_date_included: false,
                 fixed_retention: true,
                 payment_on_subscription_date: true,
                 pay_on_expiration: true,
                 retention_on_payment: true,
                 add_interests_from_parent_by_transaction: false,
                 n_days: 30,
               ))
      end

      it 'should calculate the child initial amount correctly' do
        expect(parent.theoretical_balance(promissory_note.start_date)).to eq(2_185_454.00)  
      end

      it 'should add the parent interests without the iva amount' do
        expect(promissory_note.initial_amount).to eq(2_186_546.72)
      end

      it 'should mark as applied the parent capital_payment transaction' do
        payment = parent.transactions.where(transaction_type: 'capital_payment').first
        expect(payment.status).to eq('applied')
      end
    end
  end
end
