require 'rails_helper'

describe 'French Amortization', :acceptance_spec, slow: true do
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
    Tax.find_or_initialize_by(year: 2019).update_attributes!(percentage: 1.04)
    Tax.find_or_initialize_by(year: 2020).update_attributes!(percentage: 1.45)
    Tax.find_or_initialize_by(year: 2021).update_attributes!(percentage: 0.97)
    Tax.find_or_initialize_by(year: 2022).update_attributes!(percentage: 0.97)

    Current.organization = organization
    Current.user = user
  end

  context 'IVA on amortization term' do
    describe 'Case 1' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'french_amortization',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 20,
               iva_percentage: 16,
               iva_retention_percentage: 50,
               cut_day: 15,
               monthly_periodicity: 1,
               start_date: Date.new(2021, 5, 15),
               end_date: Date.new(2022, 5, 15),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: false,
                 retention_on_payment: false,
                 iva_on_amortization_term: true
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/french_amortization_case_1.json')
        )['results']
      end

      it 'should have the correct tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the correct iva' do
        compare(cuts, results, 'iva')
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

      it 'should have the correct capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same amortization term' do
        amortization_term = cuts.first.capital_payment + cuts.first.gross + cuts.first.paid_iva
        cuts.each do |interest|
          expect(interest.capital_payment + interest.gross + interest.paid_iva).to be_within(0.01).of(amortization_term)
        end
      end
    end
  end

  context 'without iva on amortization term' do
    describe 'Case 2' do
      let(:promissory_note) do
        create(:promissory_note,
               type_of: 'french_amortization',
               initial_amount: 1_000_000,
               interest_rate: 12,
               tax_percentage: 20,
               iva_percentage: 16,
               iva_retention_percentage: 50,
               cut_day: 15,
               monthly_periodicity: 1,
               start_date: Date.new(2021, 5, 15),
               end_date: Date.new(2022, 5, 15),
               organization: organization,
               society: society,
               investor: investor,
               promoter: promoter,
               created_by: user,
               updated_by: user,
               configuration: organization.configuration.merge!(
                 day_count_algorithm: 'natural',
                 fiscal_year_days: 360,
                 start_date_excluded: true,
                 event_date_included: false,
                 end_date_excluded: false,
                 fixed_retention: false,
                 payment_on_subscription_date: false,
                 pay_on_expiration: false,
                 retention_on_payment: false,
                 iva_on_amortization_term: false
               ))
      end

      let(:cuts) { promissory_note.interests.sort_by { |cut| cut[:end_date] } }
      let(:results) do
        JSON.load(
          File.new('./lib/specs/promissory_notes/non_financial_entity/french_amortization_case_2.json')
        )['results']
      end

      it 'should have the correct tax' do
        compare(cuts, results, 'tax')
      end

      it 'should have the correct iva' do
        compare(cuts, results, 'iva')
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

      it 'should have the correct capital payment' do
        compare(cuts, results, 'capital_payment')
      end

      it 'should have the same amortization term' do
        amortization_term = cuts.first.capital_payment + cuts.first.gross
        cuts.each do |interest|
          expect(interest.capital_payment + interest.gross).to be_within(0.01).of(amortization_term)
        end
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
