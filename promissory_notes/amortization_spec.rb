require 'rails_helper'

describe 'Amortization', :acceptance_spec, slow: true do
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
    Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.04)

    Current.organization = organization
    Current.user = user
  end

  context 'Monthly' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'amortization',
               initial_amount: 10_000_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: 1,
               start_date: Date.new(2019, 1, 15),
               end_date: Date.new(2020, 1, 15),
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

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/amortization_case_1.json'))['results'] }

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

      it 'should have the same capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end

      it 'should have precise capital payment' do
        expect(cuts.map(&:capital_payment).sum).to be_within(0.01).of(promissory_note.initial_amount)
      end
    end

    describe 'Case 2' do
      let(:promissory_note) do
        create(:promissory_note,
              type_of: 'amortization',
              initial_amount: 10_000_000,
              interest_rate: 12,
              tax_percentage: 1.04,
              cut_day: 31,
              monthly_periodicity: 1,
              start_date: Date.new(2019, 1, 15),
              end_date: Date.new(2020, 1, 15),
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
                end_date_excluded: false,
                fixed_retention: false,
                payment_on_subscription_date: false
              ))
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/amortization_case_2.json'))['results'] }

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

      it 'should have the same capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end

      it 'should have precise capital payment' do
        expect(cuts.map(&:capital_payment).sum).to be_within(0.01).of(promissory_note.initial_amount)
      end
    end

    describe 'Case 5' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'amortization',
               initial_amount: 10_000_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: 1,
               start_date: Date.new(2020, 1, 15),
               end_date: Date.new(2021, 1, 15),
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
                 fixed_retention: true,
                 payment_on_subscription_date: false
               ))

        create(:promissory_note_transaction,
                               amount: 1000000,
                               date: Date.new(2020, 03, 22),
                               status: 'applied',
                               transaction_type: 'deposit',
                               promissory_note: pn
                              )

        create(:promissory_note_transaction,
                               amount: 500000,
                               date: Date.new(2020, 9, 16),
                               status: 'applied',
                               transaction_type: 'withdrawal',
                               promissory_note: pn
                              )

        pn.recalculate_from_beginning

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/amortization_case_5.json'))['results'] }

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

      it 'should have the same capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same interval gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same interval tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same interval net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same interval payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end
    end

    # end monthly context
  end
end

private

def compare(cuts, results, attribute)
  cuts.zip(results).each do |cut, result|
    expect(cut[attribute.to_sym]).to be_within(0.01).of(result[attribute.to_s])
  end
end
