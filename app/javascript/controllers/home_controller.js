import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async updateComponentPath({ target }) {
    await fetch('/roots/components', {
      method: 'PUT',
      body: JSON.stringify({ path: target.innerHTML }),
      headers: {
        'Content-Type': 'application/json'
      }
    })
  }

  async updateProjectPath({ target }) {
    await fetch('/roots/project', {
      method: 'PUT',
      body: JSON.stringify({ path: target.innerHTML }),
      headers: {
        'Content-Type': 'application/json'
      }
    })
  }
}
