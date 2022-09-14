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
    Tax.find_or_initialize_by(year: 2019).update_attributes!(percentage: 1.04)
    Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.04)
    Tax.find_or_initialize_by(year: 2021).update_attributes!(percentage: 0.97)
    Tax.find_or_initialize_by(year: 2022).update_attributes!(percentage: 0.97)

    Current.organization = organization
    Current.user = user
  end

  context 'Monthly' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'french_amortization',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 0.97,
               cut_day: 26,
               monthly_periodicity: 1,
               start_date: Date.new(2021, 1, 26),
               end_date: Date.new(2022, 4, 26),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/french_amortization_case_1.json'))['results'] }

      it 'should have the same amount of cuts' do
        expect(cuts.count).to eq(results.count)
      end

      it 'should have the same end date' do
        cuts.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the same cut days' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'number_of_days')
      end

      it 'should have the same capital payment' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'current_balance')
      end

      it 'should have precise capital payment' do
        expect(cuts.map(&:capital_payment).sum).to be_within(0.01).of(promissory_note.initial_amount)
      end

      it 'should have the same amortization term' do
        amortization_term = cuts.first.capital_payment + cuts.first.gross
        cuts.each do |interest|
          expect(interest.capital_payment + interest.gross).to be_within(0.01).of(amortization_term)
        end
      end
    end
  end
  context 'Trimestral' do
    describe 'Case 2' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'french_amortization',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 0.97,
               cut_day: 22,
               monthly_periodicity: 3,
               start_date: Date.new(2021, 11, 22),
               end_date: Date.new(2022, 11, 22),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/french_amortization_case_2.json'))['results'] }

      it 'should have the same amount of cuts' do
        expect(cuts.count).to eq(results.count)
      end

      it 'should have the same end date' do
        cuts.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the same cut days' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'number_of_days')
      end

      it 'should have the same capital payment' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'current_balance')
      end

      it 'should have the same accumulated' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'accumulated')
      end

      it 'should have precise capital payment' do
        expect(cuts.map(&:capital_payment).sum).to be_within(0.01).of(promissory_note.initial_amount)
      end
    end

    describe 'Case 3' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'french_amortization',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 0.97,
               cut_day: 15,
               monthly_periodicity: 3,
               start_date: Date.new(2021, 12, 15),
               end_date: Date.new(2022, 12, 15),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))

        create(:promissory_note_transaction,
                       amount: 100000,
                       date: Date.new(2022, 03, 15),
                       status: 'applied',
                       transaction_type: 'deposit',
                       promissory_note: pn
                      )

        pn.recalculate_from_beginning

        pn
      end

      let(:wrong_transaction) do
        {
          amount: 100000,
          date: Date.new(2022, 02, 15),
          status: 'applied',
          transaction_type: 'withdrawal',
          promissory_note: promissory_note
        }
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/french_amortization_case_3.json'))['results'] }

      it 'should have the same amount of cuts' do
        expect(cuts.count).to eq(results.count)
      end

      it 'should have the same end date' do
        cuts.zip(results).each do |cut, result|
          expect(cut[:end_date]).to eq(result['end_date'].to_date)
        end
      end

      it 'should have the same cut days' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'number_of_days')
      end

      it 'should have the same capital payment' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        # pending 'Implement monthly cut for 3.0'
        compare(cuts, results, 'current_balance')
      end

      it 'shouldn make transactions on invalid dates' do
        transaction = promissory_note.transactions.new(wrong_transaction)
        transaction.validate

        expect(transaction.errors[:date]).to include('Fecha invalida para refinanciar')
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
