import functionalModifier from 'ember-functional-modifiers';

// from https://stackoverflow.com/questions/5497073/how-to-differentiate-single-click-event-and-double-click-event
function makeDoubleClick(doubleClickCallback, singleClickCallback) {
  let clicks = 0;
  return function() {
    clicks++;
    if (clicks == 1) {
      setTimeout(function(){
        if (clicks == 1) {
          singleClickCallback && singleClickCallback();
        } else {
          doubleClickCallback && doubleClickCallback();
        }
        clicks = 0;
      }, 300);
    }
  };
}

export function onClick(element, [singleClick] /*, hash */) {
  element.addEventListener('click', makeDoubleClick(false, singleClick));
}

export default functionalModifier(onClick);
