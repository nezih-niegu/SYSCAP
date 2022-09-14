require 'rails_helper'

describe 'Simple', :acceptance_spec, slow: true do
  let(:organization) do
    organization = create(:organization, :default_configuration)
    organization.configuration['day_count_algorithm'] = '30 days'
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

  context 'Pay on expiration' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 100_000,
               interest_rate: 12,
               tax_percentage: 20,
               iva_percentage: 16,
               cut_day: 30,
               monthly_periodicity: 1,
               start_date: Date.new(2020, 1, 15),
               end_date: Date.new(2020, 6, 15),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 day_count_algorithm: '30 days',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_included: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: true,
                 retention_on_payment: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/simple_pay_on_expiration_case_1.json')
        )['results']
      end

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

      it 'should have the same interval retained iva' do
        compare(cuts, results, 'retained_iva')
      end

      it 'should have the same interval paid iva' do
        compare(cuts, results, 'paid_iva')
      end

      it 'should have the same interval net' do
        compare(cuts, results, 'net')
      end
    end
  end

  context 'Retain an iva percentage' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 100_000,
               interest_rate: 12,
               tax_percentage: 20,
               iva_percentage: 16,
               iva_retention_percentage: 40.0,
               cut_day: 30,
               monthly_periodicity: 1,
               start_date: Date.new(2020, 1, 15),
               end_date: Date.new(2020, 6, 15),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 day_count_algorithm: '30 days',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_included: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: false,
                 retention_on_payment: false
              ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/simple_retain_an_iva_percentage_case_1.json')
        )['results']
      end

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

      it 'should have the same interval retained iva' do
        compare(cuts, results, 'retained_iva')
      end

      it 'should have the same interval paid iva' do
        compare(cuts, results, 'paid_iva')
      end

      it 'should have the same interval net' do
        compare(cuts, results, 'net')
      end
    end
  end
end

private

def compare(cuts, results, attribute)
  cuts.zip(results).each do |cut, result|
    expect(cut[attribute.to_sym]).to be_within(0.01).of(result[attribute.to_s])
  end
end
