require 'rails_helper'

describe 'Mixed Rates', :acceptance_spec, slow: true do
  let(:organization) do
    organization = create(:organization, :default_configuration)
    organization.configuration['fiscal_year_days'] = 365
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

  context 'Simple' do
    describe 'Case 1: Retention on payment' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_000_000,
               interest_rate: 10,
               tax_percentage: 20.0,
               cut_day: 31,
               monthly_periodicity: 3,
               start_date: Date.new(2020, 6, 23),
               end_date: Date.new(2020, 8, 31),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               mixed_rates_attributes: [
                 { payment_type: :electronic_funds_transfer, percentage: 5.0},
                 { payment_type: :cash, percentage: 5.0}
               ],
               configuration: organization.configuration.merge!(
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: false,
                 retention_on_payment: true
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/simple_mixed_rates_case_1.json')
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

      it 'should have the same interval accumulated' do
        compare(cuts, results, 'accumulated')
      end

      it 'should have the same interval payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same interval breakdowns gross' do
        compare_breakdowns(cuts, results, 'gross')
      end

      it 'should have the same interval breakdowns tax' do
        compare_breakdowns(cuts, results, 'tax')
      end

      it 'should have the same interval breakdowns iva' do
        compare_breakdowns(cuts, results, 'iva')
      end

      it 'should have the same interval breakdowns paid iva' do
        compare_breakdowns(cuts, results, 'paid_iva')
      end

      it 'should have the same interval breakdowns net' do
        compare_breakdowns(cuts, results, 'net')
      end

      it 'should have the same interval breakdowns accumulated' do
        compare_breakdowns(cuts, results, 'accumulated')
      end
    end

    describe 'Case 2: Non retention on payment' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_000_000,
               interest_rate: 10,
               tax_percentage: 20.0,
               cut_day: 31,
               monthly_periodicity: 3,
               start_date: Date.new(2020, 6, 23),
               end_date: Date.new(2020, 8, 31),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               mixed_rates_attributes: [
                 { payment_type: :electronic_funds_transfer, percentage: 5.0},
                 { payment_type: :cash, percentage: 5.0}
               ],
               configuration: organization.configuration.merge!(
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: false,
                 retention_on_payment: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/simple_mixed_rates_case_2.json')
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

      it 'should have the same interval accumulated' do
        compare(cuts, results, 'accumulated')
      end

      it 'should have the same interval payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same interval breakdowns gross' do
        compare_breakdowns(cuts, results, 'gross')
      end

      it 'should have the same interval breakdowns tax' do
        compare_breakdowns(cuts, results, 'tax')
      end

      it 'should have the same interval breakdowns iva' do
        compare_breakdowns(cuts, results, 'iva')
      end

      it 'should have the same interval breakdowns paid iva' do
        compare_breakdowns(cuts, results, 'paid_iva')
      end

      it 'should have the same interval breakdowns net' do
        compare_breakdowns(cuts, results, 'net')
      end

      it 'should have the same interval breakdowns accumulated' do
        compare_breakdowns(cuts, results, 'accumulated')
      end
    end
  end
end

private

def compare_breakdowns(cuts, results, attribute)
  cuts.zip(results).each do |cut, result|
    cut.interest_breakdowns
       .sort_by { |breakdown| breakdown.mixed_rate.payment_type }
       .zip(result['interest_breakdowns'])
       .each do |actual, expected|
         expect(actual[attribute.to_sym]).to be_within(0.01).of(expected[attribute.to_s])
       end
  end
end

def compare(cuts, results, attribute)
  cuts.zip(results).each do |cut, result|
    actual = cut[attribute.to_sym]
    expected = result[attribute.to_s]
    expect(actual).to be_within(0.01).of(expected)
  end
end
