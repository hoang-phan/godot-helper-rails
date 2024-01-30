import { Controller } from "@hotwired/stimulus"
import { useClickOutside } from 'stimulus-use'

export default class extends Controller {
  static targets = ['query', 'searchResults']

  connect() {
    useClickOutside(this)
  }

  async filterResults() {
    const el = this.queryTarget
    const { value, dataset } = this.queryTarget
    const { selectAction, extension, root } = dataset

    const data = { query: value, select_action: selectAction, extension, root }

    const response = await fetch(`/files?${this.buildUrlQuery(data)}`)
    this.searchResultsTarget.innerHTML = await response.text()
    this.searchResultsTarget.style.display = 'block'
  }

  buildUrlQuery(data) {
    return Object.keys(data).map(
      key =>`${key}=${data[key] ? encodeURIComponent(data[key]) : ''}`
    ).join('&')
  }

  clickOutside(event) {
    this.searchResultsTarget.style.display = 'none'
  }

  displayDropdown() {
    this.searchResultsTarget.style.display = 'block'
  }

  populateContent({ target }) {
    this.queryTarget.value = target.innerHTML
    this.searchResultsTarget.style.display = 'none'
  }
}
