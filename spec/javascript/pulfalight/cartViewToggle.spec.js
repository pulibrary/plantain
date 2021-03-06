import CartViewToggle from "components/CartViewToggle"
import { render, fireEvent } from '@testing-library/vue'

describe("CartViewToggle.vue", () => {
  test("Toggling cart", async () => {
    const toggleVisibility = jest.fn()
    const store = {
      state: {
        cart: {
          items: [ {} ]
        }
      },
      mutations: {
        TOGGLE_VISIBILITY: toggleVisibility
      }
    }
    const { getByRole, container } = render(CartViewToggle, { store })
    const button = getByRole("button")
    await fireEvent.click(button)
    expect(toggleVisibility).toHaveBeenCalled()

    count = container.getElementsByClassName("badge")[0]
    expect(count.textContent.trim()).toBe("1")
  })
})
