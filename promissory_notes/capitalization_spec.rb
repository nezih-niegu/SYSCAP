require 'rails_helper'

describe 'Capitalization', :acceptance_spec, slow: true do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:society) { create(:organization_society, organization_id: organization.id) }

  let(:promoter) { create(:promoter, organization: organization, updated_by: user, created_by: user) }
  let(:investor) do
    create(:investor, organization: organization, promoter: promoter,
                      updated_by: user, created_by: user)
  end

  let(:fiscal_address) do
    create(:fiscal_address,
           source: investor,
           organization: organization,
           created_by: user,
           updated_by: user)
  end

  let(:bank_account) do
    create(:bank_account,
           source: investor,
           organization: organization,
           banxico_bank: create(:banxico_bank),
           fiscal_address: fiscal_address,
           created_by: user,
           updated_by: user)
  end

  before(:each) do
    Tax.find_or_initialize_by(year: 2017).update_attributes!(percentage: 0.58)
    Tax.find_or_initialize_by(year: 2018).update_attributes!(percentage: 0.46)
    Tax.find_or_initialize_by(year: 2019).update_attributes!(percentage: 1.04)
    Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)
    Tax.find_or_initialize_by(year: 2021).update_attributes!(percentage: 0.97)

    Tax.where(year: 2020).where(percentage: 0.5).delete_all
    Current.organization = organization
    Current.user = user
  end

  context 'Monthly' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 30,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2019, 1, 3),
               end_date: Date.new(2020, 1, 3),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: '30 days',
                 fiscal_year_days: 360,
                 start_date_excluded: false,
                 end_date_excluded: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_1.json'))['results'] }

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

      it 'should have the same interval capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same interval balance' do
        compare(cuts, results, 'current_balance')
      end
    end

    describe 'Case 2' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2019, 1, 0o3),
               end_date: Date.new(2020, 1, 0o3),
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
                 end_date_excluded: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_2.json'))['results'] }

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

      it 'should have the same interval capital payment' do
        compare(cuts, results, 'capital_payment')
      end
    end

    describe 'Case 3' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2019, 1, 3),
               end_date: Date.new(2020, 1, 3),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 end_date_excluded: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_3.json'))['results'] }

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

      it 'should have the same interval capital payment' do
        compare(cuts, results, 'capital_payment')
      end
    end

    describe 'Case 4' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               capitalization_payment: 0,
               start_date: Date.new(2018, 1, 0o3),
               end_date: Date.new(2019, 1, 0o3),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_4.json'))['results'] }

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

      it 'should have the same interval capital payment' do
        compare(cuts, results, 'capital_payment')
      end
    end

    describe 'Case 5' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 0.46,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               capitalization_payment: 0,
               start_date: Date.new(2018, 1, 0o3),
               end_date: Date.new(2019, 1, 0o3),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 end_date_excluded: true,
                 fixed_retention: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_5.json'))['results'] }

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

      it 'should have the same interval capital payment' do
        compare(cuts, results, 'capital_payment')
      end
    end

    describe 'Case 6' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 0.46,
               cut_day: 30,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2017, 8, 30),
               end_date: Date.new(2017, 10, 24),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: '30 days',
                 fiscal_year_days: 360,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_6.json'))['results'] }

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
    end

    describe 'Case 8' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2018, 11, 30),
               end_date: Date.new(2019, 12, 0o2),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'post_weekend',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 event_date_included: true,
                 start_date_excldued: true,
                 end_date_excluded: false,
                 fixed_retention: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_8.json'))['results'] }

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
    end
  end

  context 'Multi-Monthly' do
    describe 'Case 10' do
      let(:promissory_note) do
        Tax.where(year: 2020).where(percentage: 0.5).delete_all
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 10_000_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 2,
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
                 retention_on_payment: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_10.json'))['results'] }

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

      it 'should have the same interval payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end
    end

    describe 'Case 11' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 10_000_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 3,
               start_date: Date.new(2019, 1, 1),
               end_date: Date.new(2019, 12, 31),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: false,
                 fixed_retention: false,
                 retention_on_payment: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_11.json'))['results'] }

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

      it 'should have the same interval payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end
    end
  end

  context 'Retention on payment when change of year' do
    before(:each) do
      Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)
    end

    describe 'Case 12' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 6541336.94,
               interest_rate: 18,
               tax_percentage: 1.45,
               cut_day: 15,
               monthly_periodicity: nil,
               capitalization_periodicity: 3,
               start_date: Date.new(2019, 10, 15),
               end_date: Date.new(2020, 3, 20),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 retention_on_payment: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) do
        promissory_note.interests.sort_by { |cut| cut[:end_date] }
      end

      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable/case_12.json'))['results'] }

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

      it 'should have the same interval payment' do
        compare(cuts, results, 'payment')
      end

      it 'should have the same balance' do
        compare(cuts, results, 'current_balance')
      end

      it 'should have the same accumulated' do
        compare(cuts, results, 'accumulated')
      end
    end
  end

  context 'Retention on payment net and tax only on payment month' do
    before(:each) do
      Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)
    end

    describe 'Case 13' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 6541336.94,
               interest_rate: 18,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 3,
               start_date: Date.new(2020, 1, 1),
               end_date: Date.new(2020, 12, 31),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 retention_on_payment: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:cuts) do
        promissory_note.interests.order(:end_date)
      end

      it 'Get interest with payment and capitalizaiton' do
        expect(cuts.where(capitalization_interest: true).or(cuts.where(payment_interest: true)).map(&:end_date)).to match_array(
          [Date.new(2020, 3, 31), Date.new(2020, 6, 30), Date.new(2020, 9, 30), Date.new(2020, 12, 31)]
        )
      end

      it 'should not tax and net on artificial intervals' do
        create(:promissory_note_transaction,
                               amount: 50000,
                               date: Date.new(2020, 1, 15),
                               status: 'applied',
                               transaction_type: 'deposit',
                               promissory_note: promissory_note
                              )
        create(:promissory_note_transaction,
                               amount: 50000,
                               date: Date.new(2020, 2, 15),
                               status: 'applied',
                               transaction_type: 'deposit',
                               promissory_note: promissory_note
                              )
        create(:promissory_note_transaction,
                               amount: 50000,
                               date: Date.new(2020, 3, 15),
                               status: 'applied',
                               transaction_type: 'deposit',
                               promissory_note: promissory_note
                              )

        promissory_note.recalculate_from_beginning

        artificial_interests = MonthlyCutCalculator.get_promissory_note_preview(promissory_note)
                                                   .select do |interval|
          interval[:interval_id].nil?
        end

        expect(artificial_interests.count).to eq(3)
      end
    end

    describe 'Case 14' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1000000,
               interest_rate: 18,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2020, 1, 1),
               end_date: Date.new(2020, 12, 31),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 retention_on_payment: true,
                 payment_on_subscription_date: false
               ))
      end

      it 'should stop calculating interests with total_withdrawal' do
        transaction = create(:promissory_note_transaction,
                               amount: 50000,
                               date: Date.new(2020, 10, 22),
                               status: 'pending',
                               transaction_type: 'total_withdrawal',
                               promissory_note: promissory_note
                              )

        transaction.update(status: 'applied')
        promissory_note.recalculate_from_beginning

        interests = promissory_note.interests.order(:end_date)
        expect(interests.last.end_date).to eq(Date.new(2020, 10, 22))
        expect(interests.last.payment).to eq 0
      end
    end

    describe 'Case 16' do
      let(:promissory_note) do
        travel_to Date.new(2021, 2, 15)

        pn = create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_000_000,
               interest_rate: 17,
               tax_percentage: 1.45,
               cut_day: 30,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2020, 2, 19),
               end_date: Date.new(2021, 2, 28),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                   interval_skip_day: 'natural',
                   day_count_algorithm: 'natural',
                   fiscal_year_days: 365,
                   event_date_included: false,
                   start_date_excluded: true,
                   end_date_excluded: false,
                   fixed_retention: false,
                   retention_on_payment: true,
                   payment_on_subscription_date: false
               ))
      end

      it 'should pay the correct amount when withdraw all interests and total withdrawal at same date' do
        transaction = create(:promissory_note_transaction,
                             amount: 8_138.56,
                             date: Date.new(2021, 2, 15),
                             status: 'pending',
                             transaction_type: :interest_withdrawal,
                             promissory_note: promissory_note
        )
        transaction.update!(status: :applied)
        transaction = create(:promissory_note_transaction,
                             amount: 1_158_209.27,
                             date: Date.new(2021, 2, 15),
                             status: 'pending',
                             transaction_type: :total_withdrawal,
                             promissory_note: promissory_note
        )
        transaction.update!(status: :applied)

        promissory_note.reload

        interests = promissory_note.interests.order(:end_date)
        expect(interests.last.end_date).to eq(Date.new(2021, 2, 15))
        expect(interests.last.payment).to be_within(0.01).of(0.00)

        travel_back
      end
    end
  end

  context 'Retention on payment post_weekend_and_holidays and payment_on_subscription' do
    before(:each) do
      Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)
      Tax.find_or_initialize_by(year: 2021).update_attributes!(percentage: 0.97)
    end

    describe 'Case 15' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 400_000,
               interest_rate: 14,
               tax_percentage: 0.97,
               cut_day: 30,
               monthly_periodicity: nil,
               capitalization_periodicity: 3,
               start_date: Date.new(2020, 11, 30),
               end_date: Date.new(2021, 5, 31),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                   interval_skip_day: 'post_weekend_and_holiday',
                   day_count_algorithm: 'natural',
                   fiscal_year_days: 360,
                   event_date_included: false,
                   start_date_excluded: true,
                   end_date_excluded: false,
                   fixed_retention: false,
                   retention_on_payment: true,
                   payment_on_subscription_date: true
               ))
        pn.transactions.create!(amount: 50_000,
                               date: Date.new(2021, 3, 1),
                               status: :pending,
                               transaction_type: 'deposit').update!(status: :applied)

        pn.reload
        pn
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable_case_15.json'))['results'] }

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

      it 'should have the same interval capitalization accumulated' do
        compare(cuts, results, 'accumulated')
      end
    end
  end

  context 'Adding interests from parent on renewal' do
    describe 'case 1' do
      let(:parent_promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 100_000.00,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2020, 4, 2),
               end_date: Date.new(2020, 10, 2),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: true,
                 retention_on_payment: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:promissory_note) do
        create(:promissory_note,
               parent: parent_promissory_note,
               type_of: 'capitalization',
               initial_amount: parent_promissory_note.theoretical_balance(Date.new(2020, 10, 2)),
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2020, 10, 2),
               end_date: Date.new(2020, 12, 2),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 add_interests_from_parent: true,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: true,
                 retention_on_payment: false,
                 payment_on_subscription_date: false
               ))
      end

      let(:last_parent_interest) do
        parent_promissory_note.interests.order(:end_date).last
      end

      let(:last_parent_payment) do
        parent_promissory_note.payments
          .where(
              type_of: 'interests',
              date: last_parent_interest.end_date,
              recipient_type: 'Investor').first
      end

      let(:monthly_cut) do
        create(:monthly_cut,
               year: 2020,
               month: 10,
               cut_day: 31
        )
      end

      it('should add remaining interests from parent') do
        expect(promissory_note.current_balance(promissory_note.start_date)).to be_within(0.01).of(105_407.88)
        expect(last_parent_interest.reload.status_canceled?).to eq(true)
        expect(last_parent_payment.reload.status_canceled?).to eq(true)
      end

      it('should avoid to generate payments for monthly cut') do
        create(:mixed_payment_promissory_note,
               bank_account_id: bank_account.id,
               promissory_note: parent_promissory_note)

        create(:mixed_payment_promissory_note,
               bank_account_id: bank_account.id,
               promissory_note: promissory_note)

        parent_mcpn = monthly_cut.monthly_cut_promissory_notes.where(promissory_note_id: parent_promissory_note).first
        expect(monthly_cut.monthly_cut_payments.count).to eq 0
        expect(parent_mcpn.payment).to eq 0
      end
    end

    describe 'case 2' do
      let(:parent_promissory_note) do
        create(:promissory_note,
               type_of: 'capitalization',
               initial_amount: 1_000_000.00,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 20,
               capitalization_periodicity: 1,
               monthly_periodicity: nil,
               capitalization_payment: 0,
               start_date: Date.new(2020, 9, 1),
               end_date: Date.new(2020, 10, 22),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 event_date_included: false,
                 start_date_excluded: true,
                 end_date_excluded: false,
                 fixed_retention: true,
                 retention_on_payment: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:promissory_note) do
        create(:promissory_note,
               parent: parent_promissory_note,
               type_of: 'capitalization',
               initial_amount: parent_promissory_note.balance_to_date(Date.new(2020, 10, 22)),
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 20,
               capitalization_periodicity: 1,
               monthly_periodicity: nil,
               capitalization_payment: 0,
               start_date: Date.new(2020, 10, 22),
               end_date: Date.new(2020, 12, 22),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 add_interests_from_parent: true,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 event_date_included: false,
                 start_date_excluded: true,
                 end_date_excluded: false,
                 fixed_retention: true,
                 retention_on_payment: true,
                 payment_on_subscription_date: false
               ))
      end

      let(:last_parent_interest) do
        parent_promissory_note.interests.order(:end_date).last
      end

      let(:last_parent_payment) do
        parent_promissory_note.payments
          .where(type_of: 'interests',
                 date: last_parent_interest.end_date,
                 recipient_type: 'Investor').first
      end

      let(:monthly_cut) do
        create(:monthly_cut,
               year: 2020,
               month: 11,
               cut_day: 20
        )
      end

      it('should add remaining interests from parent') do
        expect(promissory_note.current_balance(promissory_note.start_date)).to be_within(0.01).of(1_015_003.23)
        expect(last_parent_interest.reload.status_canceled?).to eq(true)
        expect(last_parent_payment.reload.status_canceled?).to eq(true)
      end

      it('should avoid to generate payments for monthly cut') do
        create(:mixed_payment_promissory_note,
               bank_account_id: bank_account.id,
               promissory_note: parent_promissory_note)

        create(:mixed_payment_promissory_note,
               bank_account_id: bank_account.id,
               promissory_note: promissory_note)

        parent_mcpn = monthly_cut.monthly_cut_promissory_notes.where(promissory_note_id: parent_promissory_note).first
        expect(monthly_cut.monthly_cut_payments.count).to eq 0
        expect(parent_mcpn.payment).to eq 0
      end
    end
  end

  context 'Transactions type Capitalization' do
    describe 'Correct number of capitalizations' do
      let(:promissory_note) do
        create(
          :promissory_note,
          type_of: 'capitalization',
          initial_amount: 1000_000,
          interest_rate: 12,
          tax_percentage: 1.45,
          cut_day: 8,
          capitalization_periodicity: 1,
          monthly_periodicity: nil,
          capitalization_payment: 0,
          start_date: Date.new(2020, 4, 8),
          end_date: Date.new(2021, 4, 8),
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
          )
        )
      end

      let(:promissory_note_transaction) do
        create(
          :promissory_note_transaction,
          amount: 100_000,
          date: Date.new(2020, 11, 15),
          status: 'pending',
          transaction_type: 'deposit',
          promissory_note: promissory_note
        )
      end

      it('should have 11 transactions type capitalization') do
        promissory_note_transaction.status = 'applied'
        promissory_note_transaction.save

        transactions = promissory_note.transactions.where(transaction_type: 'capitalization')
        capital_payment = promissory_note.transactions.where(transaction_type: 'capital_payment')

        expect(transactions.count).to eq(11)
        expect(capital_payment.count).to eq(1)
      end
    end

    describe 'Use capitalization_accumulated for promissory notes capitalization_periodicity == 0' do
      let(:promissory_note) do
        create(
          :promissory_note,
          type_of: 'capitalization',
          initial_amount: 1_000_000,
          interest_rate: 12,
          tax_percentage: 0.97,
          cut_day: 8,
          monthly_periodicity: nil,
          capitalization_periodicity: 1,
          start_date: Date.new(2021, 1, 1),
          end_date: Date.new(2021, 12, 30),
          organization: organization,
          investor: investor,
          promoter: promoter,
          created_by: user,
          updated_by: user,
          configuration: organization.configuration.merge!(
            interval_skip_day: 'natural',
            day_count_algorithm: '30 days',
            fiscal_year_days: 360,
            start_date_excluded: true,
            event_date_included: false,
            end_date_excluded: false,
            fixed_retention: false,
            retention_on_payment: false,
            payment_on_subscription_date: false
          )
        )
      end

      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalization_accumulated_case_1.json'))['results'] }

      it('should have the same capitalization_accumulated') do
        compare(promissory_note.interests.sort_by(&:end_date), results, 'capitalization_accumulated')
      end
    end

    describe 'Remove iva for capitalization_accumulated' do
      let(:promissory_note) do
        non_financial_entity_society = society
        non_financial_entity_society.update!(is_financial_entity: false)
        create(
          :promissory_note,
          type_of: 'capitalization',
          initial_amount: 1_000_000,
          interest_rate: 15,
          tax_percentage: 1.45,
          cut_day: 31,
          capitalization_periodicity: 3,
          monthly_periodicity: nil,
          capitalization_payment: 0,
          iva_retention_percentage: 50,
          start_date: Date.new(2021, 1, 1),
          end_date: Date.new(2022, 2, 1),
          organization: organization,
          investor: investor,
          promoter: promoter,
          created_by: user,
          updated_by: user,
          society: non_financial_entity_society,
          configuration: organization.configuration.merge!(
            interval_skip_day: 'natural',
            day_count_algorithm: 'natural',
            iva_percentage: 16,
            iva_retention_percentage: 50,
            fiscal_year_days: 360,
            event_date_included: false,
            start_date_excluded: true,
            end_date_excluded: false,
            fixed_retention: true,
            retention_on_payment: false,
            payment_on_subscription_date: false
          )
        )
      end

      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalization_accumulated_case_2.json'))['results'] }

      it('should have the same capitalization_accumulated') do
        compare(promissory_note.interests.sort_by(&:end_date), results, 'accumulated')
      end
    end

    describe 'Transaction on the same date of Capitalization' do
      let(:promissory_note) do
        create(
          :promissory_note,
          type_of: 'capitalization',
          initial_amount: 1_000_000,
          interest_rate: 20,
          tax_percentage: 1.04,
          cut_day: 31,
          capitalization_periodicity: 1,
          monthly_periodicity: nil,
          capitalization_payment: 0,
          start_date: Date.new(2021, 1, 1),
          end_date: Date.new(2022, 2, 1),
          organization: organization,
          investor: investor,
          promoter: promoter,
          created_by: user,
          updated_by: user,
          configuration: organization.configuration.merge!(
            interval_skip_day: 'natural',
            day_count_algorithm: 'natural',
            fiscal_year_days: 360,
            event_date_included: false,
            start_date_excluded: true,
            end_date_excluded: false,
            fixed_retention: true,
            retention_on_payment: false,
            payment_on_subscription_date: false
          )
        )
      end

      let(:promissory_note_transaction) do
        create(
          :promissory_note_transaction,
          amount: 10_000,
          date: Date.new(2021, 1, 31),
          status: 'pending',
          transaction_type: 'deposit',
          promissory_note: promissory_note
        )
      end

      it('should have 2 applied transactions at the same date') do
        promissory_note_transaction.update(status: :applied)
        promissory_note.reload

        transactions = promissory_note.transactions.where(date: promissory_note_transaction.date).status_applied

        expect(transactions.count).to eq(2)
      end

      it('current balance should be capitalization + deposit') do
        promissory_note_transaction.update(status: :applied)
        promissory_note.reload
        current_balance = promissory_note.current_balance(promissory_note_transaction.date + 1.day)

        expect(current_balance).to be_within(0.01).of(1_025_800)
      end
    end
  end

  context 'Non retention on payment' do
    # Finpais - MXN3-4
    let(:promissory_note) do
      non_financial_entity_society = society
      non_financial_entity_society.update!(is_financial_entity: false)
      non_iva_organization = organization
      non_iva_organization.update!(settings: organization.configuration.merge!(iva_percentage: 0))

      create(:promissory_note,
             start_date: Date.new(2021, 2, 10),
             end_date: Date.new(2022, 2, 10),
             type_of: 'capitalization',
             capitalization_periodicity: 3,
             monthly_periodicity: nil,
             interest_rate: 15,
             cut_day: 22,
             initial_amount: 231_730.05,
             tax_percentage: 0,
             organization: non_iva_organization,
             society: non_financial_entity_society,
             investor: investor,
             promoter: promoter,
             created_by: user,
             updated_by: user,
             configuration: non_iva_organization.configuration.merge!(
               fiscal_year_days: 360,
               interval_skip_day: nil,
               day_count_algorithm: '30 days',
               event_date_included: false,
               start_date_excluded: true,
               end_date_excluded: false,
               retention_on_payment: false,
               payment_on_subscription_date: true,
               pay_on_expiration: false,
               fixed_retention: true,
               tax_percentage: 0,
               iva_percentage: 0,
               iva_retention_percentage: 0
             ))            
    end

    let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/capitalizable/non_retention_on_payment_case_1.json')) }

    it 'should have the same capitalization accumulated' do
      compare(promissory_note.interests, results['interests'], 'accumulated')
    end

    it 'transactions should have the same amount' do
      compare(promissory_note.transactions, results['transactions'], 'amount')
    end
  end
end

private

def compare(calculated, results, attribute)
  calculated.zip(results).each do |calculated_element, result|
    expect(calculated_element[attribute.to_sym]).to be_within(0.01).of(result[attribute.to_s])
  end
end
