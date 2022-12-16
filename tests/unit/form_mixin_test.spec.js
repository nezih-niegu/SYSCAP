import { expect } from 'chai'
import FormMixin from '@/mixins/form-mixin'
import Helpers from '@/mixins/helpers'

const emptyForm = {
  text: {
    label: 'Text',
    value: '',
    type: 'text'
  },
  number: {
    label: 'Number',
    value: '',
    type: 'number'
  },
  radio: {
    label: 'Choose one',
    value: '',
    type: 'radio',
    options: [
      { value: 1, label: 'one' },
      { value: 2, label: 'two' },
      { value: 3, label: 'three' }
    ]
  },
  checkbox: {
    label: 'Mark the options',
    value: [],
    type: 'checkbox',
    options: [
      { value: 1, label: 'one' },
      { value: 2, label: 'two' },
      { value: 3, label: 'three' }
    ]
  },
  select: {
    label: 'Select an option',
    value: null,
    type: 'select',
    options: [
      { value: 1, label: 'one' },
      { value: 2, label: 'two' },
      { value: 3, label: 'three' }
    ]
  },
  date: {
    label: 'Date',
    value: '',
    type: 'date'
  }
}

const fullForm = {
  text: {
    label: 'Text',
    value: 'Rodo',
    type: 'text'
  },
  number: {
    label: 'Number',
    value: '20',
    type: 'number'
  },
  radio: {
    label: 'Choose one',
    value: 'two',
    type: 'radio',
    options: [
      { value: 1, label: 'one' },
      { value: 2, label: 'two' },
      { value: 3, label: 'three' }
    ]
  },
  checkbox: {
    label: 'Mark the options',
    value: [1, 3],
    type: 'checkbox',
    options: [
      { value: 1, label: 'one' },
      { value: 2, label: 'two' },
      { value: 3, label: 'three' }
    ]
  },
  select: {
    label: 'Select an option',
    value: { value: 1, label: 'one' },
    type: 'select',
    options: [
      { value: 1, label: 'one' },
      { value: 2, label: 'two' },
      { value: 3, label: 'three' }
    ]
  },
  date: {
    label: 'Date',
    value: '2019-02-07',
    type: 'date'
  }
}

const formA = {
  aText: {
    value: 'text',
    type: 'text'
  },
  aSelect: {
    value: { value: 1, label: 'one' },
    type: 'select',
    options: { value: 1, label: 'one' }
  },
  aTextDisabled: {
    value: 'text',
    type: 'text'
  },
  aTextHidden: {
    value: 'text',
    type: 'text'
  },
  aTextInActive: {
    value: 'text',
    type: 'text'
  }
}

const formB = {
  bText: {
    value: 'text',
    type: 'text'
  },
  bSelect: {
    value: { value: 1, label: 'one' },
    type: 'select',
    options: { value: 1, label: 'one' }
  },
  bTextDisabled: {
    value: 'text',
    type: 'text'
  }
}

const rules = {
  aTextDisabled: {
    disabled: true
  },
  aTextHidden: {
    hidden: true
  },
  aTextInActive: {
    inactive: true
  },
  bTextDisabled: {
    disabled: true
  }
}

let FM = { ...FormMixin.methods, ...Helpers.methods }

describe('Form Mixin', () => {
  it('body should be an empty object when all input\'s values are null/empty', () => {
    const result = {
      text: '',
      number: '',
      radio: '',
      checkbox: [],
      select: null,
      date: ''
    }

    expect(FM.processForm(emptyForm)).to.deep.equal(result)
  })

  it('body should contains all inputs with a valid value', () => {
    const result = {
      text: 'Rodo',
      number: '20',
      radio: 'two',
      checkbox: [1, 3],
      select: 1,
      date: '2019-02-07'
    }

    expect(FM.processForm(fullForm)).to.deep.equal(result)
  })

  it('body should not contain disabled inputs', () => {
    const result = {
      aText: 'text',
      aTextHidden: 'text',
      aSelect: 1
    }

    expect(FM.processForm(formA, rules)).to.deep.equal(result)
  })

  it('body should contain hidden inputs', () => {
    const result = {
      aText: 'text',
      aTextHidden: 'text',
      aSelect: 1
    }

    expect(FM.processForm(formA, rules)).to.deep.equal(result)
  })

  it('body should not contain inactive inputs', () => {
    const result = {
      aText: 'text',
      aTextHidden: 'text',
      aSelect: 1
    }

    expect(FM.processForm(formA, rules)).to.deep.equal(result)
  })

  it('body should contains all valid inputs from a form\'s array', () => {
    const result = {
      aText: 'text',
      aTextHidden: 'text',
      aSelect: 1,
      bText: 'text',
      bSelect: 1
    }

    expect(FM.processFormArray([formA, formB], rules)).to.deep.equal(result)
  })

  it('body should have the forms\' object structure', () => {
    const result = {
      formA: {
        aText: 'text',
        aTextHidden: 'text',
        aSelect: 1
      },
      formB: {
        bText: 'text',
        bSelect: 1
      }
    }

    expect(FM.processFormObject({ formA, formB }, rules)).to.deep.equal(result)
  })

  it('body should have the inputs\' object structure, when isFlat prop is true', () => {
    const result = {
      aText: 'text',
      aTextHidden: 'text',
      aSelect: 1
    }

    expect(FM.processFormObject(formA, rules, true)).to.deep.equal(result)
  })
})
