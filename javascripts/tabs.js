(function() {
  $(document).ready(function() {
    var isTabActive, respondToTabBeingClicked, selectFirstTab, selectTab, switchContent, tabActiveClass, tabContentOpenClass, tabContentSelector, tabSelector, tabSetSelector, tabSets;
    tabSetSelector = '.accordion-tabs-minimal';
    tabSelector = '.tab-link';
    tabContentSelector = '.tab-content';
    tabActiveClass = 'is-active';
    tabContentOpenClass = 'is-open';
    tabSets = $(tabSetSelector);
    selectFirstTab = function() {
      var firstItem;
      firstItem = $(this).children('li').first();
      firstItem.find(tabSelector).addClass(tabActiveClass);
      return firstItem.find(tabContentSelector).addClass(tabContentOpenClass).show();
    };
    isTabActive = function(tab) {
      return tab.hasClass(tabActiveClass);
    };
    selectTab = function(tabSet, tab) {
      tabSet.find(tabSelector).removeClass(tabActiveClass);
      return tab.addClass(tabActiveClass);
    };
    switchContent = function(tabSet, content) {
      tabSet.find(tabContentSelector).removeClass(tabContentOpenClass).hide();
      return content.addClass(tabContentOpenClass).show();
    };
    respondToTabBeingClicked = function(event) {
      var content, tab, tabSet;
      event.preventDefault();
      tab = $(this);
      tabSet = tab.parents(tabSetSelector);
      content = tab.next(tabContentSelector);
      if (!isTabActive(tab)) {
        selectTab(tabSet, tab);
        return switchContent(tabSet, content);
      }
    };
    tabSets.each(selectFirstTab);
    return tabSets.on('click', tabSelector, respondToTabBeingClicked);
  });

}).call(this);
