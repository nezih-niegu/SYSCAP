require 'rails_helper'

describe 'Amortization', :acceptance_spec, slow: true do
  let(:organization) do
    organization = create(:organization, :default_configuration)
    organization.configuration['day_count_algorithm'] = 'natural'
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

  context 'Without retention on payment' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'amortization',
               initial_amount: 100_000,
               interest_rate: 12,
               tax_percentage: 20,
               iva_percentage: 16,
               cut_day: 31,
               monthly_periodicity: 1,
               start_date: Date.new(2020, 4, 14),
               end_date: Date.new(2020, 6, 14),
               organization: organization,
               society: society,
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
                 pay_on_expiration: false,
                 retention_on_payment: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/amortization_case_1.json')
        )['results']
      end

      it 'should have the correct gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the correct tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the correct iva' do
        compare(cuts, results, 'iva')
      end

      it 'should have the correct retained iva' do
        compare(cuts, results, 'retained_iva')
      end

      it 'should have the correct paid iva' do
        compare(cuts, results, 'paid_iva')
      end

      it 'should have the correct net' do
        compare(cuts, results, 'net')
      end

      it 'should have the correct balance' do
        compare(cuts, results, 'current_balance')
      end
    end
  end

  context 'Retention on payment' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'amortization',
               initial_amount: 100_000,
               interest_rate: 12,
               tax_percentage: 20,
               iva_percentage: 16,
               cut_day: 31,
               monthly_periodicity: 2,
               start_date: Date.new(2020, 4, 14),
               end_date: Date.new(2020, 7, 14),
               organization: organization,
               society: society,
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
                 pay_on_expiration: false,
                 retention_on_payment: true
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/amortization_with_retention_on_payment_case_1.json')
        )['results']
      end

      it 'should have the correct gross' do
        compare(cuts, results, 'gross')
      end

      it 'should have the correct tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the correct iva' do
        compare(cuts, results, 'iva')
      end

      it 'should have the correct retained iva' do
        compare(cuts, results, 'retained_iva')
      end

      it 'should have the correct paid iva' do
        compare(cuts, results, 'paid_iva')
      end

      it 'should have the correct net' do
        compare(cuts, results, 'net')
      end

      it 'should have the correct accumulated' do
        compare(cuts, results, 'accumulated')
      end

      it 'should have the correct balance' do
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
