require 'rails_helper'

describe 'Variable Rates', :acceptance_spec, slow: true, skip: 'The specs are pending to fix' do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }

  let(:promoter) { create(:promoter, organization: organization, updated_by: user, created_by: user) }
  let(:investor) do
    create(:investor, organization: organization, promoter: promoter,
                      updated_by: user, created_by: user)
  end

  before(:each) do
    Current.organization = organization
    Current.user = user

    Tax.find_or_initialize_by(year: 2019).update_attributes!(percentage: 1.04)
    Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)
    Banxico::RateFileImporter.call 'tiie', '28-days'
    Banxico::RateFileImporter.call 'tiie', '91-days'
    Banxico::RateFileImporter.call 'tiie', '182-days'
    Banxico::RateFileImporter.call 'cetes', '28-days'
  end

  context 'Simple' do
    describe 'Monthly - Case 1' do

      let!(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_861_198.72,
               additional_interest_rate: 0.75,
               tax_percentage: 1.45,
               cut_day: 31,
               includes_external_rate: true,
               external_rate_label: 'tiie',
               variable_rate_days: '28-days',
               variable_rate_date: Date.new(2019, 1, 10),
               interest_rate_floor: 0,
               interest_rate_ceiling: 100,
               monthly_periodicity: 1,
               start_date: Date.new(2019, 1, 10),
               end_date: Date.new(2020, 1, 9),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                   interval_skip_day: 'natural',
                   day_count_algorithm: 'natural',
                   fiscal_year_days: 360,
                   start_date_included: false,
                   end_date_excluded: false,
                   retention_on_payment: false,
                   fixed_retention: false,
                   payment_on_subscription_date: false
               ))
      end

      let(:interests_before) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/variable_rates_case_1.json'))['results'] }

      before do
        interests_before.zip(results).each do |cut, result|
          pn_interest_rate = promissory_note.interest_rates
                                 .where('start_date < ?', result['end_date'])
                                 .where('end_date >= ?', result['end_date']).first

          pn_interest_rate.update_columns(
              variable_rate_date: result['variable_rate_date'],
              variable_rate_value: result['variable_rate_value']
          )
          pn_interest_rate.reload
          promissory_note.recalculate_from_date(cut.start_date.next_day)
          promissory_note.reload
        end
      end

      let(:interests) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }

      it 'should have the same amount of interests' do
        expect(interests.count).to eq(results.count)
      end

      it 'should have the same end date' do
        interests.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the same cut days' do
        compare(interests, results, 'number_of_days')
      end

      it 'should have the same gross' do
        compare(interests, results, 'gross')
      end

      it 'should have the same tax' do
        compare(interests, results, 'tax')
      end

      it 'should have the same net' do
        compare(interests, results, 'net')
      end

      it 'should have the same variable rate date' do
        interests.zip(results).each do |cut, result|
          expect(cut[:variable_rate_date]).to eq(result['variable_rate_date'].to_date)
        end
      end

      it 'should have the same variable rate value' do
        compare(interests, results, 'variable_rate_value')
      end
    end

    describe 'Bimonthly - Case 2 Retention on Payment' do
      let!(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_300_000.00,
               additional_interest_rate: 0,
               tax_percentage: 1.45,
               cut_day: 31,
               includes_external_rate: true,
               external_rate_label: 'tiie',
               variable_rate_days: '28-days',
               variable_rate_date: Date.new(2019, 1, 31),
               interest_rate_floor: 0,
               interest_rate_ceiling: 100,
               monthly_periodicity: 2,
               start_date: Date.new(2019, 1, 10),
               end_date: Date.new(2020, 1, 9),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                   interval_skip_day: 'natural',
                   day_count_algorithm: 'natural',
                   fiscal_year_days: 360,
                   start_date_included: false,
                   start_date_excluded: true,
                   end_date_excluded: false,
                   event_date_included: false,
                   retention_on_payment: true,
                   fixed_retention: false,
                   payment_on_subscription_date: false
               ))
      end

      let(:interests_before) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/variable_rates_case_2.json'))['results'] }

      before do
        interests_before.zip(results).each do |cut, result|
          pn_interest_rate = promissory_note.interest_rates
                                 .where('start_date < ?', result['end_date'])
                                 .where('end_date >= ?', result['end_date']).first

          pn_interest_rate.update_columns(
              variable_rate_date: result['variable_rate_date'],
              variable_rate_value: result['variable_rate_value']
          )
          pn_interest_rate.reload
          promissory_note.recalculate_from_date(cut.start_date.next_day)
          promissory_note.reload
        end
      end

      let(:interests) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }

      it 'should have the same amount of interests' do
        expect(interests.count).to eq(results.count)
      end

      it 'should have the same end date' do
        interests.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the same cut days' do
        compare(interests, results, 'number_of_days')
      end

      it 'should have the same accumulated' do
        compare(interests, results, 'accumulated')
      end

      it 'should have the same gross' do
        compare(interests, results, 'gross')
      end

      it 'should have the same tax' do
        compare(interests, results, 'tax')
      end

      it 'should have the same net' do
        compare(interests, results, 'net')
      end

      it 'should have the same variable rate date' do
        interests.zip(results).each do |cut, result|
          expect(cut[:variable_rate_date]).to eq(result['variable_rate_date'].to_date)
        end
      end

      it 'should have the same variable rate value' do
        compare(interests, results, 'variable_rate_value')
      end
    end
  end

  context 'Capitalization' do
    describe 'Monthly - Case 3' do
      let!(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_861_198.72,
               additional_interest_rate: 0.75,
               tax_percentage: 1.45,
               cut_day: 31,
               includes_external_rate: true,
               external_rate_label: 'tiie',
               variable_rate_days: '28-days',
               variable_rate_date: Date.new(2019, 1, 10),
               interest_rate_floor: 0,
               interest_rate_ceiling: 100,
               monthly_periodicity: 1,
               capitalization_payment: 0,
               start_date: Date.new(2019, 1, 10),
               end_date: Date.new(2020, 1, 9),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                   interval_skip_day: 'natural',
                   day_count_algorithm: 'natural',
                   fiscal_year_days: 365,
                   start_date_included: false,
                   end_date_excluded: false,
                   retention_on_payment: false,
                   fixed_retention: false,
                   payment_on_subscription_date: false
               ))
      end

      let(:interests_before) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/variable_rates_case_3.json'))['results'] }

      before do
        interests_before.zip(results).each do |cut, result|
          pn_interest_rate = promissory_note.interest_rates
                                 .where('start_date < ?', result['end_date'])
                                 .where('end_date >= ?', result['end_date']).first

          pn_interest_rate.update_columns(
              variable_rate_date: result['variable_rate_date'],
              variable_rate_value: result['variable_rate_value']
          )
          pn_interest_rate.reload
          promissory_note.recalculate_from_date(cut.start_date.next_day)
          promissory_note.reload
        end
      end

      let(:interests) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }

      it 'should have the same amount of interests' do
        expect(interests.count).to eq(results.count)
      end

      it 'should have the same end date' do
        interests.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the same cut days' do
        compare(interests, results, 'number_of_days')
      end

      it 'should have the same current balance' do
        compare(interests, results, 'current_balance')
      end

      it 'should have the same gross' do
        compare(interests, results, 'gross')
      end

      it 'should have the same tax' do
        compare(interests, results, 'tax')
      end

      it 'should have the same net' do
        compare(interests, results, 'net')
      end

      it 'should have the same variable rate date' do
        interests.zip(results).each do |cut, result|
          expect(cut[:variable_rate_date]).to eq(result['variable_rate_date'].to_date)
        end
      end

      it 'should have the same variable rate value' do
        compare(interests, results, 'variable_rate_value')
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
