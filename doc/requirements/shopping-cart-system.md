# Shopping Cart System

## Overview
This document describes a dummy shopping cart system for an e-commerce site.

## Functional requirements
- FR-1: Users can add products to the cart.
- FR-2: Users can update item quantities in the cart.
- FR-3: Users can remove items from the cart.
- FR-4: Users can view the cart summary before checkout.
- FR-5: The system can calculate subtotal, discounts, tax, and total.

## Non-functional requirements
- NFR-1: Cart updates should appear immediately after each user action.
- NFR-2: Cart state should persist for returning users during the same session.
- NFR-3: The cart page should remain usable on desktop and mobile devices.

## Assumptions
- Product catalog data is already available to the shopping cart service.
- Pricing and discount rules are provided by upstream business logic.

## Out of scope
- Payment processing.
- Order fulfillment.
- Inventory management.
