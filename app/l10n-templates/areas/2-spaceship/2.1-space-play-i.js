console.log('area', area);
area.on('start finish-edit', function() {
  console.log('area edit/start', level);
  /*
  var officeDoor = level.find('.office-door');
  if (levels('2.5').hasErrors || levels('2.6').hasErrors || levels('2.7').hasErrors || levels('2.8').hasErrors) {
    officeDoor.data.ignore = false;
    officeDoor.el.style.display = 'block';
  } else {
    officeDoor.data.ignore = true;
    officeDoor.el.style.display = 'none';

    if (!area.state.get('playedFixShipCutscene')) {
      game.playVideo('2-spaceship/fix-ship');
      area.state.set('playedFixShipCutscene', true);
    }
  }
  */
});
