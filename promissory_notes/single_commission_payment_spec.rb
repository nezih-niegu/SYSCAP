require 'rails_helper'

describe 'Single Commission Payment', :acceptance_spec, slow: true, skip: 'Fix infinite loop first' do
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
  end

  context 'Single payment vs Monthly Payment' do
    describe 'Case 1' do
      let(:promissory_note) do 
        {
          type_of: 'simple',
          initial_amount: 2_000_000,
          interest_rate: 12,
          tax_percentage: 1.04,
          cut_day: 2,
          monthly_periodicity: 1,
          start_date: Date.new(2021, 8, 3),
          end_date: Date.new(2022, 8, 1),
          promoter_commission: 1.5,
          organization: organization,
          investor: investor,
          promoter: promoter,
          created_by: user,
          updated_by: user,
          configuration: organization.configuration.merge!(
           interval_skip_day: 'pre_weekend',
           day_count_algorithm: 'natural',
           fiscal_year_days: 360,
           start_date_excluded: true,
           end_date_excluded: true,
           fixed_retention: true,
           payment_on_subscription_date: false
          )
        }
      end

      let(:single_payment) do
        promissory_note[:configuration].merge!(single_commission_payment: true)
        create(:promissory_note, promissory_note)
      end

      let(:monthly_payment) do
        promissory_note[:configuration].merge!(single_commission_payment: false)
        create(:promissory_note, promissory_note)
      end

      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/commission_payment_case_1.json'))['results'] }

      it 'should have the same commission sum' do
        pending 'Fix infinite loop'
        expect(single_payment.interests.sum(:commission)).to eq(monthly_payment.interests.sum(:commission))
      end

      it 'single payment should match with the results' do
        pending 'Fix infinite loop'
        compare_comissions(single_payment.interests, results['single_payment'])
      end

      it 'monthly payment should match with the results' do
        pending 'Fix infinite loop'
        compare_comissions(monthly_payment.interests, results['monthly_payment'])
      end
    end

    describe 'case 2' do
      let(:promissory_note) do 
        {
          type_of: 'capitalization',
          initial_amount: 1_000_000,
          interest_rate: 12,
          tax_percentage: 1.04,
          cut_day: 2,
          monthly_periodicity: 1,
          capitalization_payment: 0,
          start_date: Date.new(2021, 8, 3),
          end_date: Date.new(2022, 8, 1),
          promoter_commission: 1.5,
          organization: organization,
          investor: investor,
          promoter: promoter,
          created_by: user,
          updated_by: user,
          configuration: organization.configuration.merge!(
           interval_skip_day: 'pre_weekend',
           day_count_algorithm: 'natural',
           fiscal_year_days: 360,
           start_date_included: false,
           end_date_excluded: true,
           fixed_retention: true,
           payment_on_subscription_date: false,
           tax_configuration: "interest_post_tax"
          )
        }
      end

      let(:single_payment) do
        promissory_note[:configuration].merge!(single_commission_payment: true)
        create(:promissory_note, promissory_note)
      end

      let(:monthly_payment) do
        promissory_note[:configuration].merge!(single_commission_payment: false)
        create(:promissory_note, promissory_note)
      end

      let(:results) { JSON.load(File.new('./lib/specs/promissory_notes/commission_payment_case_2.json'))['results'] }

      it 'should have the same commission sum' do
        expect(single_payment.interests.sum(:commission)).to eq(monthly_payment.interests.sum(:commission))
      end

      it 'single payment should match with the results' do
        compare_comissions(single_payment.interests, results['single_payment'])
      end

      it 'monthly payment should match with the results' do
        compare_comissions(monthly_payment.interests, results['monthly_payment'])
      end

    end
  end
end

private

def compare_comissions(interests, results)
  interests.zip(results).each do |cut, result|
    expect(cut[:commission]).to be_within(0.01).of(result['interval_commission'])
  end
end
