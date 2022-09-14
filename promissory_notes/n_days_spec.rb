require 'rails_helper'

describe 'N_Days', :acceptance_spec, slow: true do
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
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: 1,
               start_date: Date.new(2020, 1, 1),
               end_date: Date.new(2020, 11, 11),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 n_days: 28,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_included: false,
                 end_date_excluded: false,
                 retention_on_payment: false,
                 fixed_retention: false,
                 payment_on_subscription_date: true
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/n_days_case_1.json'))['results'] }

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

      it 'should have the same gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
      end
    end

    describe 'Case 2' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'simple',
               initial_amount: 2_000_000,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: 1,
               start_date: Date.new(2019, 11, 6),
               end_date: Date.new(2020, 11, 11),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 n_days: 28,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: false,
                 retention_on_payment: false,
                 fixed_retention: false,
                 payment_on_subscription_date: true
               ))

        create(:promissory_note_transaction,
                               amount: 1000000,
                               date: Date.new(2019, 11, 21),
                               status: 'applied',
                               transaction_type: 'withdrawal',
                               promissory_note: pn
                              )

        pn.recalculate_from_beginning

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/n_days_case_2.json'))['results'] }

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

      it 'should have the same gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
      end
    end

    describe 'Case 4' do
      before do
        travel_to Date.new(2021, 5, 11)
      end

      after do
        travel_back
      end

      let(:promissory_note) do
        organization.configuration['n_days'] = 28
        organization.configuration['payment_on_subscription_date'] = true
        organization.configuration['retention_on_payment'] = true
        organization.configuration['end_date_excluded'] = true
        organization.configuration['start_date_excluded'] = true
        organization.save!

        pn = create(:promissory_note,
               initial_amount: 70228.6,
               tax_percentage: 0.97,
               cut_day: 16,
               monthly_periodicity: nil,
               capitalization_periodicity: 1,
               start_date: Date.new(2021, 2, 16),
               end_date: Date.new(2022, 2, 16),
               interest_rate: 10.0,
               canceled_date: nil,
               promoter_commission: 0.0,
               includes_external_rate: false,
               interest_rate_ceiling: 100.0,
               interest_rate_floor: 0.0,
               investor: investor,
               promoter: promoter,
               organization: organization,
               status: 'active',
               currency: 'mxn',
               external_rate_label: nil,
               configuration: {
                   n_days: 28,
                   cut_days: [31],
                   currencies: ["mxn"],
                   tiie_rates: nil,
                   cetes_rates: nil,
                   notifications: {
                       investor_birthday: false,
                       missing_documentation: false,
                       expiration_promissory_note: {
                           days: [1, 15, 30],
                           users: ["Investor", "Promoter", "Admin"],
                           active: false
                       }
                   },
                   interest_table: 'autogenerate',
                   iva_percentage: 16.0,
                   tax_percentage: 0.97,
                   fixed_retention: false,
                   libor_usd_rates: nil,
                   fiscal_year_days: 360,
                   admin_users_limit: 5,
                   end_date_excluded: true,
                   interval_skip_day: nil,
                   pay_on_expiration: false,
                   tax_configuration: 'interest_pre_tax',
                   start_date_excluded: true,
                   day_count_algorithm: 'natural',
                   electronic_signature: {},
                   retention_on_payment: true,
                   add_interests_from_parent: false,
                   promissory_note_folio_scope: 'investor_id',
                   payment_on_subscription_date: true,
                   promissory_note_folio_pattern: '',
                   statement_monthly_periodicity: 0,
                   renew_promissory_notes_by_changes: true,
                   mutable: nil
               },
               promoter_payment_method: nil,
               type_of: 'capitalization',
               folio: '900013027',
               iva_percentage: 0.0,
               capitalization_payment: 0,
               variable_rate_days: nil,
               variable_rate_date: nil,
               additional_interest_rate: 0.0,
               iva_retention_percentage: 0.0,
               sequential_folio: 27,
               extra_fields: nil,
               interests_from_parent_already_added: false
        )

        create(:promissory_note_transaction,
               amount: 8027.58,
               date: Date.new(2021, 5, 11),
               promissory_note: pn,
               organization: organization,
               status: 'applied',
               transaction_type: 'withdrawal',
               tax: 0.0,
               iva: 0.0
        )

        pn.recalculate_from_beginning
        pn.reload
      end

      it 'should not delete capitalization on transaction confirmation' do
        capitalization = promissory_note.transactions.transaction_type_capitalization.where(date: '2021-05-11').first
        interest = promissory_note.interests.where(end_date: '2021-05-11').first
        expect(capitalization).to_not be_nil
        expect(interest.tax).to_not eql 0
        expect(interest.net).to_not eql 0
      end
    end
  end

  context 'Multi-Monthly' do
    describe 'Case 3' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: 3,
               start_date: Date.new(2020, 1, 1),
               end_date: Date.new(2020, 11, 11),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 n_days: 28,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_included: false,
                 end_date_excluded: false,
                 retention_on_payment: false,
                 fixed_retention: false,
                 payment_on_subscription_date: true
               ))
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/n_days_case_3.json'))['results'] }

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

      it 'should have the same gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
      end
    end

    describe 'Case 4' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'simple',
               initial_amount: 2_000_000,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: 2,
               start_date: Date.new(2019, 11, 6),
               end_date: Date.new(2020, 11, 11),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 n_days: 28,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: false,
                 retention_on_payment: false,
                 fixed_retention: false,
                 payment_on_subscription_date: true
               ))

        create(:promissory_note_transaction,
                               amount: 1000000,
                               date: Date.new(2019, 11, 21),
                               status: 'applied',
                               transaction_type: 'withdrawal',
                               promissory_note: pn
                              )

        pn.recalculate_from_beginning

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/n_days_case_4.json'))['results'] }

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

      it 'should have the same gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
      end
    end

    describe 'Case 5' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'simple',
               initial_amount: 2_000_000,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: 2,
               start_date: Date.new(2019, 11, 6),
               end_date: Date.new(2020, 11, 11),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 n_days: 28,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: false,
                 retention_on_payment: true,
                 fixed_retention: false,
                 payment_on_subscription_date: true
               ))

        create(:promissory_note_transaction,
                               amount: 1000000,
                               date: Date.new(2019, 11, 21),
                               status: 'applied',
                               transaction_type: 'withdrawal',
                               promissory_note: pn
                              )

        pn.recalculate_from_beginning

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/n_days_case_5.json'))['results'] }

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

      it 'should have the same gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
      end
    end

    describe 'Case 6', skip: 'Decide whether start date excluded should apply with n-days or not' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'simple',
               initial_amount: 2_000_000,
               interest_rate: 12,
               tax_percentage: 1.45,
               cut_day: 31,
               monthly_periodicity: 2,
               start_date: Date.new(2019, 11, 6),
               end_date: Date.new(2020, 11, 11),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 n_days: 28,
                 interval_skip_day: 'natural',
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: true,
                 retention_on_payment: false,
                 fixed_retention: false,
                 payment_on_subscription_date: true
               ))

        create(:promissory_note_transaction,
                               amount: 1000000,
                               date: Date.new(2019, 11, 20),
                               status: 'applied',
                               transaction_type: 'withdrawal',
                               promissory_note: pn
                              )

        create(:promissory_note_transaction,
                               amount: 1000000,
                               date: Date.new(2019, 12, 18),
                               status: 'applied',
                               transaction_type: 'deposit',
                               promissory_note: pn
                              )

        create(:promissory_note_transaction,
                               amount: 1000000,
                               date: Date.new(2020, 1, 1),
                               status: 'applied',
                               transaction_type: 'withdrawal',
                               promissory_note: pn
                              )

        pn.recalculate_from_beginning

        pn
      end

      let(:cuts) { promissory_note.interests.all.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/n_days_case_6.json'))['results'] }

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

      it 'should have the same gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the same tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the same net' do
        compare(cuts, results, 'net')
      end

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
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
