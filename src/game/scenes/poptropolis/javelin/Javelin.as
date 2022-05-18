package game.scenes.poptropolis.javelin
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.item.ItemMotion;
	import game.components.input.Input;
	import game.components.motion.Edge;
	import game.components.motion.Threshold;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.poptropolis.JavelinAnim;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.MatchType;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Javelin extends PoptropolisScene
	{
		
		private const MAX_ROUNDS:int = 3;
		
		private const FLOOR:Number = 755;
		private const THROW_BUFFER:Number = 30;
		private const PLATFORM_ANGLE:Number = 9.2;
		private const PLATFORM_WIDTH:Number = 380;
		private const MAX_POWER:Number = 200;
		
		private var stopx:Number;
		private var stopy:Number;
		
		private var _heatTextClip:MovieClip;
		private var _eventTextClip:MovieClip;
		
		private var _groundedJavelins:Vector.<Entity>;
		private var _javelinEntity:Entity;
		private var _powerHud:Entity;
		private var _angleHud:Entity;
		
		private var _startPosition:Point; 
		private var _practicing:Boolean = true;
		private var _foul:Boolean = false;
		private var _currentRound:Number = 0;
		private var _bestScore:Number;
		private var _angle:Number;
		private var _power:Number;
		private var _hud:JavelinHud;
		
		
		public function Javelin()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/javelin/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;
			
			//apply tribe look
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			SkinUtils.applyLook( super.player, playerLook, false ); 
			
			// create angle hud
			var clip:MovieClip;
			clip = MovieClip( MovieClip(super._hitContainer).angleHud_mc );
			DisplayUtils.moveToTop( clip );
			_angleHud = EntityUtils.createSpatialEntity( this, clip );
			TimelineUtils.convertClip( clip, this, _angleHud, null, false );
			_angleHud.add( new Sleep( true, true ) );
			
			// create power hud
			clip = MovieClip( MovieClip(super._hitContainer).powerHud_mc );
			DisplayUtils.moveToTop( clip );
			_powerHud = EntityUtils.createSpatialEntity( this, clip );
			TimelineUtils.convertClip( clip, this, _powerHud, null, false );
			_powerHud.add( new Sleep( true, true ) );
			
			// create javelin
			_javelinEntity = EntityUtils.createMovingEntity(this, super.getAsset("javelinClip.swf") as MovieClip, super._hitContainer);
			var threshold:Threshold = new Threshold( "y", ">" )
			threshold.threshold = FLOOR;
			_javelinEntity.add( threshold );
			super.addSystem( new ThresholdSystem() );
			_javelinEntity.add( new Sleep( true, true ) );
			
			// create landed javelins
			_groundedJavelins = new Vector.<Entity>()
			for (var i:int = 1; i <= MAX_ROUNDS; i++) 
			{
				clip = MovieClip(super._hitContainer['javelin_'+i]); 		
				var groundJavelinEntity:Entity = EntityUtils.createSpatialEntity(this, clip, super._hitContainer);
				groundJavelinEntity.add( new Sleep( true, true ) );
				_groundedJavelins.push( groundJavelinEntity );
			}
			
			// text
			_heatTextClip = MovieClip(super._hitContainer['heatTXT']);
			_eventTextClip = MovieClip(super._hitContainer['eventTXT']);
			
			// refresh text	// TODO : set format & outline
			//_heatTextClip.attemptTXT = TextUtils.refreshText( _heatTextClip.attemptTXT );
			//_eventTextClip.attemptTXT = TextUtils.refreshText( _eventTextClip.attemptTXT );
			//_eventTextClip.largeTXT = TextUtils.refreshText( _eventTextClip.largeTXT );
			//_eventTextClip.farthestTXT = TextUtils.refreshText( _eventTextClip.farthestTXT );
			
			_heatTextClip.alpha = 0;
			_heatTextClip.scaleX = .4;
			_heatTextClip.scaleY = .4;
			
			_eventTextClip.alpha = 0;
			_eventTextClip.scaleX = .4;
			_eventTextClip.scaleY = .4;
			
			// lock player & give javelin item
			_startPosition = EntityUtils.getPosition( super.player );
			CharUtils.lockControls( super.player );
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM, false );
			
			
			_hud = super.addChildGroup(new JavelinHud(super.overlayContainer)) as JavelinHud;
			_hud.stopRaceClicked.add(onStopRaceClicked)
			_hud.exitClicked.add(onExitPracticeClicked)
			_hud.ready.addOnce(initHud);
			
			
			super.loaded();
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, openInstructionsPopup ));	
		}
		
		
		
		override protected function onStartClicked(): void 
		{
			_hud.setMode("game")
			startMatch(false);
		}
		
		override protected function onPracticeClicked(): void 
		{
			_hud.setMode("practice")
			startMatch(true);
		}
		
		private function startMatch( isPractice:Boolean ):void 
		{
			
			_practicing = isPractice;			
			_currentRound = 0;
			_bestScore = 0;
			
			// reset all ground javelins
			for (var i:int = 0; i < _groundedJavelins.length; i++) 
			{
				Sleep(_groundedJavelins[i].get(Sleep)).sleeping = true;
			}
			
			startRound();
		}
		
		public function startRound():void
		{
			// reset huds
			Sleep(_angleHud.get(Sleep)).sleeping = true;
			Sleep(_powerHud.get(Sleep)).sleeping = true;
			
			if ( _currentRound < MAX_ROUNDS )	// continue to next round
			{	
				//reposition char
				player.get(Spatial).x = _startPosition.x;
				player.get(Spatial).y = _startPosition.y;
				
				//set camera to player
				SceneUtil.setCameraTarget( this, player );
				SceneUtil.lockInput( this, false );
				
				_currentRound++;
				
				// turn on angle hud
				Sleep(_angleHud.get(Sleep)).sleeping = false;
				Timeline(_angleHud.get(Timeline)).gotoAndPlay(1);
				MovieClip(_angleHud.get(Display).displayObject)["glow"]["glow"].alpha = 0;
				
				// set character to Javelin animation
				CharUtils.setAnim(player,game.data.animation.entity.character.poptropolis.JavelinAnim);
				CharUtils.getTimeline( player ).gotoAndPlay("breathe");		
				
				// hide item
				Display(CharUtils.getPart( super.player, CharUtils.ITEM ).get(Display)).visible = false;
				
				showHeatText(_currentRound);
				SceneUtil.getInput( this ).inputDown.addOnce( angleChosen );
			}
			else						// rounds ended
			{
				if( _practicing )
				{
					//reposition char
					player.get(Spatial).x = _startPosition.x;
					player.get(Spatial).y = _startPosition.y;
					
					//set camera to player
					SceneUtil.setCameraTarget( this, player );
					SceneUtil.lockInput( this, false );

					// set character to Javelin animation
					CharUtils.setAnim(player,game.data.animation.entity.character.poptropolis.JavelinAnim);
					CharUtils.getTimeline( player ).gotoAndPlay("breathe");
					openInstructionsPopup();
				}
				else
				{
					//unlock inoput
					SceneUtil.lockInput( this, false );
					
					var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
					// TODO :: need to exit out of scene at this point
					var curMatch:MatchType = Matches.getMatchType(Matches.JAVELIN);
					pop.onResultsDone.addOnce(Command.create(onResultsDone, curMatch.eventName));
					pop.setup();
				}
			}						
		}
		
		////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////// HUDS ///////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////
		
		private function angleChosen( input:Input=null  ):void
		{
			// stop angle hud
			var timeline:Timeline = _angleHud.get(Timeline);
			timeline.stop();
			
			// determine angle from timeline
			var fireNumber:Number = timeline.currentIndex;
			if (fireNumber > 60) fireNumber = 60 - (fireNumber - 60);
			_angle = -(fireNumber*1.5);	
			
			trace(">>>>>>>ANGLE :"+_angle+" : "+fireNumber);
			
			//_angle = -45;
			
			if ((fireNumber >= 20 && fireNumber <=25) || (fireNumber >= 35 && fireNumber <=40)){
				super.shellApi.triggerEvent("pickYellowAngleSFX");
			}else if (fireNumber >= 26 && fireNumber <=34){
				super.shellApi.triggerEvent("pickGreenAngleSFX");
				
			}
			
			SceneUtil.getInput( this ).inputUp.addOnce( choosePower );
		}
		
		private function choosePower( input:Input=null  ):void
		{
			// start power hud & listen for click
			Sleep(_powerHud.get(Sleep)).sleeping = false;
			var timeline:Timeline = _powerHud.get(Timeline);
			timeline.gotoAndPlay(1);
			
			timeline.handleLabel( "reachedEnd", powerChosen );
			SceneUtil.getInput( this ).inputDown.addOnce( powerChosen );
		}
		
		private function powerChosen( input:Input=null  ):void
		{
			Timeline( _powerHud.get(Timeline) ).removeLabelHandler( powerChosen );
			SceneUtil.getInput( this ).inputDown.remove( powerChosen );
			
			// stop powerHud & retrieve power
			Timeline(_powerHud.get(Timeline)).stop();
			_power = Math.abs( MovieClip(Display(_powerHud.get(Display)).displayObject).marker.y );
			if (_power < 177){
				super.shellApi.triggerEvent("pickYellowPowerSFX");
			}else if (_power < 200){
				super.shellApi.triggerEvent("pickGreenPowerSFX");
				MovieClip(_angleHud.get(Display).displayObject)["glow"]["glow"].alpha = 1;
			}
			
			trace(">>>>>>>>>>>>>>>POWER : "+_power)
						
			SceneUtil.getInput( this ).inputUp.removeAll();
			SceneUtil.lockInput( this );
			
			// load javelin part
			var skinPart:SkinPart = SkinUtils.getSkinPart( player, SkinUtils.ITEM );
			if( skinPart.value != "javelin" )
			{
				SkinUtils.setSkinPart( player, SkinUtils.ITEM, "javelin", false, onPartLoaded );
			}
			else
			{
				onPartLoaded();
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////// THROW SEQUENCE //////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////
		
		private function onPartLoaded( skinPart:SkinPart = null ):void
		{
			// unhide item
			Display(CharUtils.getPart( super.player, CharUtils.ITEM ).get(Display)).visible = true;
			
			// hide huds
			Sleep(_angleHud.get(Sleep)).sleeping = true;
			Sleep(_powerHud.get(Sleep)).sleeping = true;
			
			// override item angle to match angle
			var itemEntity:Entity = CharUtils.getPart( super.player, CharUtils.ITEM );
			itemEntity.remove( ItemMotion );
			Spatial(itemEntity.get(Spatial)).rotation = _angle + 90;
			
			var displayObject:MovieClip = itemEntity.get(Display).displayObject as MovieClip;
			var glowClip0:MovieClip = displayObject.getChildByName( "glow0_mc" ) as MovieClip;
			var glowClip1:MovieClip = displayObject.getChildByName( "glow1_mc" ) as MovieClip;
			
			trace("power: "+ _power +" : "+ _angle);
			
			//trying to make glow mcs turn on inside character item...
			if (_power >=166 && _power <= 200 && _angle >= -51 && _angle <= -39)
			{
				glowClip0.alpha = 1;	
				glowClip1.alpha = 1;	
			}
			else if (_angle >= -51 && _angle <= -39)
			{
				glowClip0.alpha = 1;
				glowClip1.alpha = 0;	
			}
			else if (_power >=166 && _power <= 200)
			{
				glowClip0.alpha = 1;
				glowClip1.alpha = 0;	
			}
			else
			{
				glowClip0.alpha = 0;	
				glowClip1.alpha = 0;
			}
			
			//determine final point
			var reachedFunction:Function;
			if ( _power > MAX_POWER )
			{
				_foul = true;
				_power = MAX_POWER * 1.5;
				reachedFunction = startFall;
			}
			else
			{
				_foul = false;
				reachedFunction = startToss;
			}
			
			var xTarget:Number = _power/MAX_POWER * PLATFORM_WIDTH;
			var yTarget:Number = Math.tan( GeomUtils.degreeToRadian( PLATFORM_ANGLE ) ) * xTarget;
			stopx = _startPosition.x + xTarget;
			stopy = _startPosition.y - yTarget;
			var duration:Number = ( Math.floor( _power * 2.15 ) ) / 300
			
			TweenUtils.entityTo( player, Spatial, duration, { x:stopx, y:stopy, onComplete:reachedFunction, ease:Sine.easeIn});	
			CharUtils.getTimeline( player ).gotoAndPlay("runStart");
		}
		
		////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////// FOUL ///////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////
		
		public function startFall():void
		{		
			CharUtils.setState(super.player, CharacterState.FALL );
			var motion:Motion = super.player.get(Motion) as Motion;
			motion.velocity.x = _power/2;
			
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = FLOOR - 250;
			threshold.entered.addOnce(dropJavelin);
			player.add( threshold );
			
			var fsmControl:FSMControl = player.get(FSMControl);
			if( !fsmControl.stateChange )
			{
				fsmControl.stateChange = new Signal();
			}
			fsmControl.stateChange.add( onLand );
		}
		
		public function dropJavelin():void
		{
			super.player.remove( Threshold);
			
			// hide item
			var itemPart:Entity = CharUtils.getPart( super.player, CharUtils.ITEM );
			Display(itemPart.get(Display)).visible = false;
			
			Sleep( _javelinEntity.get(Sleep) ).sleeping = false;
			var playerSpatial:Spatial = player.get(Spatial);
			var playerEdge:Edge = player.get(Edge);
			EntityUtils.position(_javelinEntity, playerSpatial.x, playerSpatial.y);
			_javelinEntity.get(Spatial).rotation = -25 + Math.random() * 10;
			Threshold( _javelinEntity.get( Threshold ) ).entered.addOnce( javelinLanded );
			
			var motion:Motion = _javelinEntity.get(Motion) as Motion;
			motion.velocity.x = _power/2 + Math.random() * 200;
			motion.velocity.y = Motion( player.get( Motion ) ).velocity.y;
			motion.rotationVelocity = 75; 
		}
		
		public function onLand( state:String, entity:Entity ):void
		{
			if( state == CharacterState.LAND )
			{
				var motion:Motion = super.player.get(Motion) as Motion;
				motion.velocity.x = 0;
				
				var fsmControl:FSMControl = player.get(FSMControl);
				fsmControl.stateChange.remove( onLand );
				
				Display(CharUtils.getPart( super.player, CharUtils.ITEM ).get(Display)).visible = false;	// hide item
				startDust();						// start partciles
				CharUtils.setAnim(player, Dizzy);	// set animation
				CharUtils.getTimeline( player ).gotoAndPlay("startParticles");	// jump to later frame in dizzy
				super.shellApi.triggerEvent("notPickedSFX");
			}
		}
		
		public function startDust():void{
			
			var dustEmitter:Dust = new Dust(); 
			var spatial:Spatial = super.player.get( Spatial );
			var edge:Edge = super.player.get( Edge );
			EmitterCreator.create(this, super._hitContainer, dustEmitter, spatial.x, spatial.y + edge.rectangle.bottom ); 
			dustEmitter.init();
		}
		
		////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////// THROW ///////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////
		
		public function startToss():void
		{
			CharUtils.getTimeline( player ).gotoAndPlay("throwStart");
			Timeline(CharUtils.getTimeline(player)).handleLabel("trigger", startThrow );
		}
		
		public function startThrow():void
		{
			super.shellApi.triggerEvent("throwJavelinSFX");
			// hide item
			Display(CharUtils.getPart( super.player, CharUtils.ITEM ).get(Display)).visible = false;
			
			// position javelin & set camera to follow
			Sleep(_javelinEntity.get(Sleep)).sleeping = false;
			var playerSpatial:Spatial = player.get(Spatial);
			var playerEdge:Edge = player.get(Edge);
			EntityUtils.position(_javelinEntity, playerSpatial.x + playerEdge.rectangle.left, playerSpatial.y + playerEdge.rectangle.top);
			SceneUtil.setCameraTarget( this, _javelinEntity );	
			
			// set up velocity for javelin
			var startSpeed:Number = (((stopx - 256)*2.55)+100)/12;
			trace (startSpeed+" : "+stopx+" : "+_angle)
			
			var displayObject:MovieClip = _javelinEntity.get(Display).displayObject as MovieClip;
			var glowClip0:MovieClip = displayObject.getChildByName( "glow0_mc" ) as MovieClip;
			var glowClip1:MovieClip = displayObject.getChildByName( "glow1_mc" ) as MovieClip;
			
			//trying to make glow mcs turn on inside character item...
			if (_power >=166 && _power <= 200 && _angle >= -51 && _angle <= -39)
			{
				glowClip0.alpha = 1;	
				glowClip1.alpha = 1;	
			}
			else if (_angle >= -51 && _angle <= -39)
			{
				glowClip0.alpha = 1;
				glowClip1.alpha = 0;	
			}
			else if (_power >=166 && _power <= 200)
			{
				glowClip0.alpha = 1;
				glowClip1.alpha = 0;	
			}
			else
			{
				glowClip0.alpha = 0;	
				glowClip1.alpha = 0;
			}
			
			var xMulti:Number = 16.7;
			var yMulti:Number = 10;
			var yStart:Number = 10;
			
			_angle = _angle/2;
			
			
			if(_angle < -22.5)
			{
				xMulti = xMulti - (((-(_angle)-22.5)*.45)+.5);
				yMulti = yMulti + ((-(_angle)-22.5)*.08);
				yStart = yStart - ((-(_angle)-22.5)*.08);
			}
			
			var fireRot:Number = _angle + 22.5;
			if (fireRot != 0) fireRot = fireRot/20;			
			if (fireRot < 0) fireRot = -fireRot;
			
			
			Spatial(_javelinEntity.get(Spatial)).rotation = (-(_angle+22.5)*2)-35;
			
			//figure out velocity vector
			var xSpeed:Number = startSpeed * Math.cos((_angle+90) * (Math.PI/180));
			var ySpeed:Number = (0 - startSpeed) * Math.sin((_angle+90) * (Math.PI/180));	
			
			var motion:Motion = _javelinEntity.get(Motion);
			motion.velocity.x = xSpeed*xMulti;
			motion.velocity.y = ySpeed*yStart;
			motion.acceleration.y = -(ySpeed)*yMulti;
			motion.acceleration.x = xSpeed*xMulti;			
			motion.rotationVelocity = 10;
			motion.rotationAcceleration = -ySpeed/(3.2-fireRot);
			
			Threshold( _javelinEntity.get( Threshold ) ).entered.addOnce( javelinLanded );
		}
		
		/**
		 * Called when javelin hots the ground, this triggers scoring and progression to next round or end of game 
		 * 
		 */
		public function javelinLanded():void
		{
			// replace throwing javelin with groundedJavelin
			var spatial:Spatial = _javelinEntity.get(Spatial);
			spatial.y = FLOOR;
			Sleep(_javelinEntity.get(Sleep)).sleeping = true;
			
			var javelinGroundEntity:Entity = _groundedJavelins[ _currentRound -1 ];
			Sleep( javelinGroundEntity.get(Sleep) ).sleeping = false;	
			EntityUtils.positionByEntity(javelinGroundEntity, _javelinEntity);
			javelinGroundEntity.get(Spatial).rotation = spatial.rotation;
			
			// display text
			if( _foul )
			{
				_eventTextClip.x = 805;
				showEventText(0, _currentRound, _bestScore);
			}
			else
			{
				_eventTextClip.x = spatial.x;
				var playerScore:Number = Math.round(( _eventTextClip.x + 20 - 786.75)/14.325);
				if (playerScore < 0) playerScore = 0;
				if (playerScore > _bestScore){
					_bestScore = playerScore;
					SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, newBestScore));	
				}
				
				showEventText(playerScore, _currentRound, _bestScore);
			}
			super.shellApi.triggerEvent("javelinLandedSFX");
		}
		
		public function newBestScore():void{
			super.shellApi.triggerEvent("beatScoreSFX");
		}
		
		public function showHeatText(_currentRound:int):void 
		{
			if(_practicing != true)
			{
				switch(_currentRound) 
				{
					case 1:
						_heatTextClip.attemptTXT.text = "First attempt";
						break;
					case 2:
						_heatTextClip.attemptTXT.text = "Second attempt";
						break;
					case 3:
						_heatTextClip.attemptTXT.text = "Final attempt";
						break;
				}
			} 
			else 
			{
				_heatTextClip.attemptTXT.text = "Practice attempt";
			}			
			
			TweenMax.to(_heatTextClip, .3, {scaleX:1, scaleY:1, alpha:1, onComplete:HideHeatText});
		}
		
		public function HideHeatText():void 
		{	
			TweenMax.to(_heatTextClip, .3, {scaleX:.4, scaleY:.4, alpha:0, delay:2});	
		}
		
		public function showEventText(score:Number, attempt:Number, _bestScore:Number):void 
		{
			// set text
			if(score > 0){
				_eventTextClip.largeTXT.text = score + " Meters!";
			} else {
				_eventTextClip.largeTXT.text = "Fouled!";
			}
			if(_practicing != true){
				switch(attempt) {
					case 1:
						_eventTextClip.attemptTXT.text = "First attempt:";
						break;
					case 2:
						_eventTextClip.attemptTXT.text = "Second attempt:";
						break;
					case 3:
						_eventTextClip.attemptTXT.text = "Final attempt:";
						break;
				}
			}else{
				_eventTextClip.attemptTXT.text = "Practice attempt:";
			}
			if (_bestScore > 0) {
				_eventTextClip.farthestTXT.text = "Your farthest distance: " + _bestScore + " Meters";
			} else {
				_eventTextClip.farthestTXT.text = "";
			}
			
			//_eventTextClip._y = -_root.camera._y + 210;
			_eventTextClip.visible = true;
			_eventTextClip.xscale = 40;
			_eventTextClip.yscale = 40;
			_eventTextClip.alpha = 100;
			
			TweenMax.to(_eventTextClip, .3, {scaleX:1, scaleY:1, alpha:1, onComplete:HideEventText});			
		}
		
		public function HideEventText():void 
		{	
			TweenMax.to(_eventTextClip, .3, {scaleX:.4, scaleY:.4, alpha:0, delay:3, onComplete:startRound});
		}
		
		public function dataLoaded( pop:Poptropolis ):void {
			
			pop.reportScore( Matches.JAVELIN, _bestScore, false);
		}
		
		private function initHud (hud:JavelinHud):void {
			_hud.setMode("clear")
		}
		
		private function onExitPracticeClicked (): void {
			abortRace()
		}
		
		private function onStopRaceClicked (): void {
			abortRace()
		}
		
		private function abortRace ():void {
			super.shellApi.loadScene(game.scenes.poptropolis.javelin.Javelin);
			
		}
		
	}
}