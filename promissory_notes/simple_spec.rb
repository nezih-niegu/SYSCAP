require 'rails_helper'

describe 'Simple', :acceptance_spec, slow: true do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:promoter) do
    create(:promoter, organization: organization,
                      updated_by: user, created_by: user)
  end
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

  context 'On expiry' do
    describe 'Case 9' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_500_000,
               interest_rate: 12,
               tax_percentage: 1.04,
               cut_day: 31,
               monthly_periodicity: 1,
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
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_included: true,
                 fixed_retention: true,
                 payment_on_subscription_date: false,
                 pay_on_expiration: true,
                 retention_on_payment: true
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/simple_case_9.json'))['results'] }

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

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
      end
    end
  end

  context 'With retention on payment' do
    describe 'Case 10' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'simple',
               initial_amount: 100_000,
               interest_rate: 12,
               tax_percentage: 1.45,
               iva_percentage: 16,
               cut_day: 31,
               monthly_periodicity: 1,
               start_date: Date.new(2020, 4, 14),
               end_date: Date.new(2020, 8, 14),
               organization: organization,
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
                 pay_on_expiration: true,
                 retention_on_payment: true
               ))
        transaction = PromissoryNote::Transaction.create!(
          promissory_note: pn,
          transaction_type: :total_withdrawal,
          date: Date.new(2020, 6, 14)
        )
        transaction.update!(status: :applied)
        pn.reload
        pn
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/simple_case_10.json'))['results'] }

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

      it 'should have the same payment' do
        compare(cuts, results, 'payment')
      end
    end
  end

  context 'With start date included' do
    describe 'Case 9' do
      let(:promissory_note) do
        pn = create(:promissory_note,
               type_of: 'simple',
               initial_amount: 1_330_000,
               interest_rate: 12,
               tax_percentage: 1.44,
               cut_day: 31,
               monthly_periodicity: 1,
               start_date: Date.new(2020, 5, 2),
               end_date: Date.new(2020, 9, 2),
               organization: organization,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 365,
                 start_date_excluded: false,
                 event_date_included: true,
                 end_date_excluded: true,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: false,
                 retention_on_payment: false
               ))

        transaction = pn.transactions.create!(
          amount: 50_000,
          date: Date.new(2020, 7, 30),
          transaction_type: :withdrawal
        )
        transaction.status_applied!

        pn
      end

      let(:cuts) { promissory_note.interests.order(:end_date) }
      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/simple_case_11.json'))['results'] }

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

      it 'should have the same interval current balance' do
        compare(cuts, results, 'current_balance')
      end
    end
  end

  context 'With start date included and end date excluded' do
    describe 'Case 9' do
      let(:promissory_note) do
        pn = create(:promissory_note,
                    type_of: 'simple',
                    initial_amount: 900_000,
                    interest_rate: 15,
                    tax_percentage:0.97,
                    cut_day: 31,
                    monthly_periodicity: 1,
                    start_date: Date.new(2020, 11, 1),
                    end_date: Date.new(2021, 6, 8),
                    organization: organization,
                    investor: investor,
                    promoter: promoter,
                    created_by: user,
                    updated_by: user,
                    configuration: organization.configuration.merge!(
                        day_count_algorithm: 'natural',
                        fiscal_year_days: 360,
                        start_date_excluded: false,
                        event_date_included: true,
                        end_date_excluded: true,
                        fixed_retention: false,
                        payment_on_subscription_date: false,
                        pay_on_expiration: false,
                        retention_on_payment: true
                    ))

        transaction = pn.transactions.create!(
            amount: 100_000,
            date: Date.new(2021, 6, 8),
            transaction_type: :deposit
        )
        transaction.status_applied!

        pn.reload
      end

      it 'should have zero days counted at last interval' do
        interest = promissory_note.interests.find_by_end_date Date.new(2021, 6, 8)

        expect(interest.number_of_days).to eql 0
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
