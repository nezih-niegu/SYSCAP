require 'rails_helper'

describe 'Capitalization', :acceptance_spec, slow: true do
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
    Tax.find_or_initialize_by(year: 2021).update_attributes!(percentage: 0.97)

    Current.organization = organization
    Current.user = user
  end

  context 'With-Payment-Periodicity' do
    describe 'Capitalisimple - Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 450_000,
               interest_rate: 18,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: 3,
               capitalization_periodicity: 1,
               start_date: Date.new(2019, 8, 6),
               end_date: Date.new(2020, 8, 6),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 retention_on_payment: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_with_payments_case_1.json'))['results'] }

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

      it 'should have the same interval net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same interest payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end
    end

    describe 'Capitalisimple - Case 2' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 207_846.19,
               interest_rate: 10,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: 2,
               capitalization_periodicity: 1,
               start_date: Date.new(2019, 11, 1),
               end_date: Date.new(2020, 10, 30),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'post_holiday',
                 day_count_algorithm: '30 days',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 retention_on_payment: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_with_payments_case_2.json'))['results'] }

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

      it 'should have the same interval net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same interest payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end
    end

    describe 'Capitalisimple - Case 3 - Retention on Payment' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 207_846.19,
               interest_rate: 10,
               tax_percentage: 1.04,
               cut_day: 10,
               monthly_periodicity: 3,
               capitalization_periodicity: 1,
               start_date: Date.new(2019, 12, 10),
               end_date: Date.new(2020, 12, 10),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'post_weekend_and_holiday',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 retention_on_payment: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_with_payments_case_3.json'))['results'] }

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

      it 'should have the same interval net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same interest payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end
    end

    describe 'Capitalisimple - Case 4 - With Transaction type Deposit' do
      let(:promissory_note) do
        pn = create(:promissory_note,
             type_of: 'capitalization',
             initial_amount: 450_000,
             interest_rate: 18,
             tax_percentage: 1.04,
             cut_day: 31,
             monthly_periodicity: 3,
             capitalization_periodicity: 1,
             start_date: Date.new(2019, 8, 6),
             end_date: Date.new(2020, 8, 6),
             organization: organization,
             investor: investor,
             promoter: promoter,
             created_by: user,
             updated_by: user,
             configuration: organization.configuration.merge!(
               interval_skip_day: 'natural',
               day_count_algorithm: 'natural',
               fiscal_year_days: 360,
               start_date_excluded: true,
               event_date_included: false,
               end_date_excluded: false,
               fixed_retention: false,
               retention_on_payment: false,
               payment_on_subscription_date: false
             ))
        create(:promissory_note_transaction,
                             amount: 500000,
                             date: Date.new(2020, 02, 15),
                             status: 'applied',
                             transaction_type: 'deposit',
                             promissory_note: pn
                            )
        pn.recalculate_from_beginning

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_with_payments_case_4.json'))['results'] }

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

    describe 'Capitalisimple - Case 5 - With Transaction on end_date && payment_on_subscription_date with post_weekend_and_holiday' do
      let(:promissory_note) do
        pn = create(:promissory_note,
             type_of: 'capitalization',
             initial_amount: 400_000,
             interest_rate: 16,
             cut_day: 31,
             monthly_periodicity: 3,
             capitalization_periodicity: 1,
             start_date: Date.new(2020, 8, 3),
             end_date: Date.new(2021, 8, 3),
             organization: organization,
             investor: investor,
             promoter: promoter,
             created_by: user,
             updated_by: user,
             configuration: organization.configuration.merge!(
               interval_skip_day: 'post_weekend_and_holiday',
               day_count_algorithm: 'natural',
               fiscal_year_days: 360,
               start_date_excluded: true,
               event_date_included: false,
               end_date_excluded: false,
               fixed_retention: false,
               retention_on_payment: false,
               payment_on_subscription_date: true
             ))
        create(:promissory_note_transaction,
                             amount: 100000,
                             date: Date.new(2020, 9, 2),
                             status: 'applied',
                             transaction_type: 'deposit',
                             promissory_note: pn
                            )

        create(:promissory_note_transaction,
                             amount: 100000,
                             date: Date.new(2020, 10, 1),
                             status: 'applied',
                             transaction_type: 'deposit',
                             promissory_note: pn
                            )

        create(:promissory_note_transaction,
                             amount: 100000,
                             date: Date.new(2020, 11, 3),
                             status: 'applied',
                             transaction_type: 'deposit',
                             promissory_note: pn
                            )

        create(:promissory_note_transaction,
                             amount: 100000,
                             date: Date.new(2020, 12, 1),
                             status: 'applied',
                             transaction_type: 'deposit',
                             promissory_note: pn
                            )

        create(:promissory_note_transaction,
                             amount: 200000,
                             date: Date.new(2021, 1, 4),
                             status: 'applied',
                             transaction_type: 'deposit',
                             promissory_note: pn
                            )
        pn.recalculate_from_beginning

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_with_payments_case_5.json'))['results'] }

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

    describe 'Capitalisimple - Case 6 - With Transaction type Withdrawal' do
      before do
        # we need to fake current date in order to avoid validation errors when
        # applying a transaction
        travel_to Date.new(2021, 1, 1)
      end

      after do
        travel_back
      end

      let(:promissory_note) do
        pn = create(:promissory_note,
                    type_of: 'capitalization',
                    initial_amount: 2_851_640.84,
                    interest_rate: 18,
                    tax_percentage: 1.45,
                    cut_day: 31,
                    monthly_periodicity: 3,
                    capitalization_periodicity: 1,
                    start_date: Date.new(2020, 3, 31),
                    end_date: Date.new(2021, 3, 31),
                    organization: organization,
                    investor: investor,
                    promoter: promoter,
                    created_by: user,
                    updated_by: user,
                    configuration: organization.configuration.merge!(
                        interval_skip_day: 'natural',
                        day_count_algorithm: 'natural',
                        fiscal_year_days: 360,
                        start_date_excluded: true,
                        event_date_included: false,
                        end_date_excluded: false,
                        fixed_retention: false,
                        retention_on_payment: false,
                        payment_on_subscription_date: false
                    ))
        transaction_1 = create(:promissory_note_transaction,
           amount: 500_000,
           date: Date.new(2020, 11, 20),
           transaction_type: 'withdrawal',
           status: 'pending',
           promissory_note: pn
        )
        transaction_1.status_applied!
        pn.transactions.transaction_type_capitalization.status_applied.delete_all
        transaction_2 = create(:promissory_note_transaction,
           amount: 224_552.89,
           date: Date.new(2021, 1, 1),
           status: 'pending',
           transaction_type: 'withdrawal',
           promissory_note: pn
        )
        transaction_2.status_applied!

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_with_payments_case_6.json'))['results'] }

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

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
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
