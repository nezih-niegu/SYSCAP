require 'rails_helper'

describe 'N_Days', :acceptance_spec,
         slow: true,
         skip: 'This feature was never implemented. Now we have custom periodicities' do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }

  let(:promoter) { create(:promoter, organization: organization, updated_by: user, created_by: user) }
  let(:investor) do
    create(:investor, organization: organization, promoter: promoter,
                      updated_by: user, created_by: user)
  end

  before(:each) do
    Tax.find_or_initialize_by(year: 2017).update_attributes!(percentage: 0.58)
    Tax.find_or_initialize_by(year: 2018).update_attributes!(percentage: 0.46)
    Tax.find_or_initialize_by(year: 2019).update_attributes!(percentage: 1.04)
    Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)

    Current.organization = organization
    Current.user = user
  end

  context 'Monthly' do
    describe 'Case 5' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 20,
               monthly_periodicity: 1,
               start_date: Date.new(2018, 12, 18),
               end_date: Date.new(2020, 1, 20),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { IntervalCalculator.new(promissory_note).cut_promissory_into_intervals }
      # let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/first_payment_cut/case_5.json'))['results'] }

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

      it 'should have the same interval_id' do
        compare(cuts, results, 'interval_id')
      end
    end
    # end monthly context
  end

  context 'Multi-Monthly' do
    describe 'Case 2' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 20,
               monthly_periodicity: 2,
               start_date: Date.new(2019, 1, 14),
               end_date: Date.new(2020, 1, 20),
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
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { IntervalCalculator.new(promissory_note).cut_promissory_into_intervals }
      # let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/first_payment_cut/case_2.json'))['results'] }

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

      it 'should have the same interval_id' do
        compare(cuts, results, 'interval_id')
      end
    end

    describe 'Case 3' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 20,
               monthly_periodicity: 2,
               start_date: Date.new(2018, 12, 28),
               end_date: Date.new(2020, 1, 21),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 start_date_included: true,
                 end_date_excluded: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { IntervalCalculator.new(promissory_note).cut_promissory_into_intervals }
      # let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/first_payment_cut/case_3.json'))['results'] }

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

      it 'should have the same interval_id' do
        compare(cuts, results, 'interval_id')
      end
    end
    # end multi monthly
  end
end

private

def compare(cuts, results, attribute)
  cuts.zip(results).each do |cut, result|
    expect(cut[attribute.to_sym]).to be_within(0.01).of(result[attribute.to_s])
  end
end
