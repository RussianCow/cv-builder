const techElements = Array.from(document.querySelectorAll('[data-tech]'))
for (const techElement of techElements) {
    techElement.addEventListener('mouseover', event => {
        const tech = event.target.getAttribute('data-tech')
        const relevantElements = techElements.filter(el =>
            el.getAttribute('data-tech') === tech
        )
        for (const el of relevantElements) {
            el.classList.add('active')
        }
    })

    techElement.addEventListener('mouseout', () => {
        for (const el of techElements) {
            el.classList.remove('active')
        }
    })
}
