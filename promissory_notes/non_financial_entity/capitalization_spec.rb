require 'rails_helper'

describe 'Capitalization', :acceptance_spec, slow: true do
  let(:organization) do
    organization = create(:organization, :default_configuration)
    organization.configuration['day_count_algorithm'] = 'natural'
    organization.configuration['fixed_retention'] = false
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

  before(:each) do
    Tax.find_or_initialize_by(year: 2017).update_attributes!(percentage: 0.58)
    Tax.find_or_initialize_by(year: 2018).update_attributes!(percentage: 0.46)
    Tax.find_or_initialize_by(year: 2019).update_attributes!(percentage: 1.04)
    Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)

    Current.organization = organization
    Current.user = user
  end

  context 'Retention on payment' do
    describe 'First capitalization of promissory note' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 4_000_000,
               interest_rate: 16,
               tax_percentage: 20,
               iva_percentage: 16,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 6,
               start_date: Date.new(2020, 6, 1),
               end_date: Date.new(2023, 5, 31),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: false,
                 retention_on_payment: true
               ))
      end

      let(:interest) do
        promissory_note.interests
                       .where(start_date: '2020-11-01')
                       .where(end_date: '2020-11-30').first!
      end

      it 'should have the correct gross' do
        expect(interest.gross).to be_within(0.01).of 52602.7397
      end

      it 'should have the correct tax' do
        expect(interest.tax).to be_within(0.01).of 10520.5479
      end

      it 'should have the correct iva' do
        expect(interest.iva).to be_within(0.01).of 8416.4383
      end

      it 'should have the correct retained iva' do
        expect(interest.retained_iva).to be_within(0.01).of 0.00
      end

      it 'should have the correct paid iva' do
        expect(interest.paid_iva).to be_within(0.01).of 8416.4383
      end

      it 'should have the correct net' do
        expect(interest.net).to be_within(0.01).of 50498.6301
      end

      it 'should have the correct accumulated' do
        expect(interest.accumulated).to be_within(0.01).of 306358.3561
      end

      it 'should have the correct capitalization accumulated' do
        expect(interest.capitalization_accumulated).to be_within(0.01).of 255298.6301
      end
    end

    describe 'Capitalization 3.0 capitalization periodicity equal 2' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_000_000,
               interest_rate: 15,
               tax_percentage: 20,
               iva_percentage: 16,
               iva_retention_percentage: 50,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 2,
               start_date: Date.new(2021, 1, 1),
               end_date: Date.new(2021, 6, 30),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                   day_count_algorithm: 'natural',
                   fiscal_year_days: 360,
                   start_date_excluded: false,
                   end_date_excluded: false,
                   fixed_retention: false,
                   payment_on_subscription_date: false,
                   pay_on_expiration: false,
                   retention_on_payment: true
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/non_financial_entity/capitalization_case_3.json'))['results'] }

      it 'should have the same amount of cuts' do
        expect(cuts.count).to eq(results.count)
      end

      it 'should have the same end date' do
        cuts.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the same cut days' do
        compare(cuts, results, 'number_of_days')
      end

      it 'should have the same interval gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same interval tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same interval iva' do
        compare(cuts, results, 'iva')
      end

      it 'should have the same interval retained_iva' do
        compare(cuts, results, 'retained_iva')
      end

      it 'should have the same interval paid' do
        compare(cuts, results, 'paid_iva')
      end

      it 'should have the same interval net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same interval accumulated' do
        compare(cuts, results, 'accumulated')
      end

      it 'should have the same interval payment' do
        compare(cuts, results, 'payment')
      end
    end
  end

  context 'No Retention on payment' do
    describe 'Capitalizations from capitalization_accumulated' do
      let(:promissory_note) do
        non_financial_entity_society = society
        company_investor = investor

        non_financial_entity_society.update!(is_financial_entity: false)
        company_investor.update!(company_name: 'test', company: true, is_financial_entity: false)

        create(:promissory_note,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               tax_percentage: 0,
               initial_amount: 1_000_000,
               interest_rate: 20,
               start_date: '2020-08-15',
               end_date: '2020-12-31',
               type_of: 'capitalization',
               cut_day: 31,
               organization: organization,
               society: non_financial_entity_society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                   day_count_algorithm: 'natural',
                   fiscal_year_days: 365,
                   start_date_excluded: true,
                   event_date_included: false,
                   end_date_excluded: false,
                   fixed_retention: false,
                   payment_on_subscription_date: false,
                   pay_on_expiration: false,
                   retention_on_payment: false
               ))
      end

      let(:interests) do
        promissory_note.interests.order(:end_date)
      end

      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/non_financial_entity/capitalization_case_2.json'))['results'] }

      it 'should have the same end date' do
        interests.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the correct balance' do
        compare(interests, results, 'current_balance')
      end

      it('should have the same capitalization_accumulated') do
        compare(interests, results, 'capitalization_accumulated')
      end
    end
  end
end

private

def compare(calculated, results, attribute)
  calculated.zip(results).each do |calculated_element, result|
    expect(calculated_element[attribute.to_sym]).to be_within(0.01).of(result[attribute.to_s])
  end
end
