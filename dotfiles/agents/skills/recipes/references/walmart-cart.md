# Walmart pickup cart

Use this workflow when the user asks to add ingredients for specific recipes to their Walmart cart. Add needed groceries for pickup and report the result. Never check out, submit payment, or place an order.

## Build the ingredient list

Read each requested recipe Page with the Pages tools. Resolve titles against the collection and ask only when the recipe target is ambiguous. Use the requested servings or the recipe's saved yield. Read quantities and preparation details from the recipe itself, not the directory's ingredient count. Do not edit recipe Pages or use ingredient checklist state as pantry inventory.

Combine compatible ingredients across recipes, converting units when supported. Retain distinctions that affect the dish, such as salted versus unsalted butter or fresh versus dried garlic. Pick one supported alternative. Include optional ingredients and sides only when requested.

For a homemade component such as Cajun Garlic Butter Sauce, read its linked recipe and scale its ingredients to the amount needed. If the recipe calls for a purchased sauce, buy that product instead. If the intended homemade or purchased version is unclear and changes the groceries, ask. Do not add both a prepared component and its ingredients. Keep the directory's ingredient counting convention unchanged.

Track each ingredient's required amount, evidence of supplies at home, usable amount already in the cart, remaining amount to buy, and selected product/package quantity. Keep this shopping list in the active task. Do not store home addresses or purchase history in the skill, dotfiles, or recipe Pages.

## Open Walmart in Chrome

Use the available browser/computer-use tool to open [Walmart](https://www.walmart.com/) in Chrome. Reuse the user's signed-in session. Follow the tool's documented browser controls. Do not use a different browser or extract cookies or credentials as a workaround.

If signed out, ask the user to sign in in Chrome and resume after sign-in is confirmed. Let the user handle any authentication challenge. If Chrome cannot be controlled, report that limitation without claiming the cart was updated.

Select Pickup and the closest Walmart offering pickup to the user's home. Use a clearly identified saved home address or a location the user supplied. Compare the stores and distances Walmart shows for that location. A selected store or browser geolocation alone does not establish home. If the home location is missing or ambiguous, ask for the home location needed to choose the store. Do not claim the store is closest if the available evidence only supports a rough area.

Verify the store and pickup mode before choosing products. Preserve unrelated cart items and their quantities. If changing stores or fulfillment would change unrelated items, resolve that conflict with the user before making those changes. Do not book a pickup slot or enter checkout to complete this task.

## Check what is already available

Inspect the existing cart and recent relevant purchase history visible in the signed-in account. Use completed pickups or delivered orders as evidence of a purchase. Pending or canceled orders and earlier cart additions do not prove an ingredient reached the house. Read only the history needed for these ingredients. If history is unavailable, disclose the gap and continue from the recipe, current cart, and user-provided supplies.

- If the user confirms an ingredient is at home in sufficient quantity, skip it. If they give a remaining quantity, subtract that amount.
- If a recent purchase or another concrete clue suggests an ingredient may still be at home, ask a focused question. For example, "You bought garlic last week. Do you still need garlic?" Only include a date or purchase claim supported by the visible evidence.
- Batch uncertain items into one short question when practical. Hold those ingredients while adding the clearly needed items. A missing reply is not confirmation that the ingredient is at home or that it should be bought.
- Without evidence of supplies at home, add the required ingredient. Do not assume salt, oil, spices, or other staples are already owned merely because they are common.
- Subtract compatible items already in the cart from the shopping amount. Cart contents prevent duplicate additions but do not establish pantry inventory. If a matching item uses another fulfillment method, do not count it toward pickup without resolving that difference.

Recent purchases alone do not establish how much remains. Do not invent a pantry balance or skip garlic solely because the user recently cooked garlic chicken.

## Select and add products

Search for each remaining ingredient at the selected store. Match the recipe's form and any user-specified brand, dietary requirements, or preferences. Otherwise choose a reasonable, inexpensive equivalent and enough practical packages to cover the needed amount. Prefer a small sufficient package over bulk quantities. For an amount stated as "to taste," use a modest standard package if the ingredient is needed.

Use visible package sizes and prices to calculate quantities. Label unavoidable estimates, such as loose produce quantities, rather than claiming exact coverage. Ask when missing quantities prevent a reasonable purchase. If a product is unavailable for pickup or a substitution would materially change the dish, hold that ingredient and ask about the alternative. Do not silently switch it to delivery or shipping.

Before each addition or quantity increase, check the current matching cart quantity. Add only the remaining deficit. After an interrupted or uncertain action, read the cart before retrying so a successful earlier addition is not repeated. Do not reduce pre-existing quantities or remove unrelated products.

## Verify and report

Read the cart after the changes. Verify the selected pickup store, fulfillment of the added items, product matches, package quantities, and any duplicates. Compare the verified cart against the ingredient list. Treat an Add button click as unverified until the resulting cart contents are visible.

Report the pickup store, what was added and in what quantities, what was already covered by the cart or confirmed supplies at home, and any ingredients awaiting an answer or unavailable for pickup. Include the estimated added-item subtotal when visible and distinguish it from the whole cart total. Link to the Walmart cart using its observed URL. State that no order was placed.

If some additions failed or cannot be verified, report partial completion accurately. Leave uncertain pantry ingredients pending for the user's answer and resume by checking the cart again. Stop with the cart prepared for pickup. Leave checkout and ordering to the user.
