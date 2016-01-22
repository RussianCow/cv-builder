(function() {
    var techElements = document.querySelectorAll('[data-tech]')
    techElements = Array.prototype.slice.apply(techElements)
    techElements.forEach(function(techElement) {
        techElement.addEventListener('mouseover', function() {
            var tech = this.getAttribute('data-tech')
            var relevantElements = techElements.filter(function(el) {
                return el.getAttribute('data-tech') === tech
            })
            relevantElements.forEach(function(el) {
                el.classList.add('active')
            })
        })

        techElement.addEventListener('mouseout', function() {
            techElements.forEach(function(el) {
                el.classList.remove('active')
            })
        })
    })
})()
