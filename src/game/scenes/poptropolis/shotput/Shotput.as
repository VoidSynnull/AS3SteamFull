package game.scenes.poptropolis.shotput{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.motion.Edge;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.motion.Threshold;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.ShotputAnim;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.poptropolis.shotput.ShotputHud;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.Utils;


	
	public class Shotput extends PoptropolisScene
	{

		public var angle_mc:MovieClip;
		public var power_mc:MovieClip;
		public var line_mc:MovieClip;
		public var heatTXT:MovieClip;
		public var eventTXT:MovieClip;
		public var btn_mc:MovieClip;
		public var ballEntity:Entity;
		public var ballSpacial:Spatial;
		public var angleArray:Array;
		public var clickCnt:Number;
		public var curRound:Number;
		public var practicing:Boolean = false;
		public var bestScore:Number;
		public var fireangle:Number; 
		private var _hud:ShotputHud;
		private var eventEntity:Entity;
		private var heatEntity:Entity;

		
		public function Shotput()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/shotput/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			//apply tribe look
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			SkinUtils.applyLook( super.player, playerLook, false ); 
			
			addButton("btn", handleButtonClicked);
			
			btn_mc = MovieClip(super._hitContainer['btn']);
			angle_mc = MovieClip(super._hitContainer['angle_mc']);
			power_mc = MovieClip(super._hitContainer['power_mc']);
			line_mc = MovieClip(super._hitContainer['line_mc']);
			heatTXT = MovieClip(super._hitContainer['heatTXT']);
			eventTXT = MovieClip(super._hitContainer['eventTXT']);
			var water_mc:MovieClip = MovieClip(super._hitContainer['water_mc']);
			
			heatTXT.alpha = 0;
			heatTXT.scaleX = .4;
			heatTXT.scaleY = .4;
			eventTXT.alpha = 0;
			eventTXT.scaleX = .4;
			eventTXT.scaleY = .4;
			
			_hud = super.addChildGroup(new ShotputHud(super.overlayContainer)) as ShotputHud;
			_hud.stopRaceClicked.add(onStopRaceClicked)
			_hud.exitClicked.add(onExitPracticeClicked)
			_hud.ready.addOnce(initHud);
			
			heatEntity = EntityUtils.createSpatialEntity(this, heatTXT, super.overlayContainer);
			heatEntity.add(new Tween());
			var display:Display = heatEntity.get(Display);
			var spatial:Spatial = heatEntity.get(Spatial);
			display.alpha = 0;
			spatial.x = shellApi.viewportWidth/2 - 100;
			spatial.y = shellApi.viewportHeight/2 + 100;
			spatial.scaleX = spatial.scaleY = .4;
			
			eventEntity = EntityUtils.createSpatialEntity(this, eventTXT, super.overlayContainer);
			eventEntity.add(new Tween());
			display = eventEntity.get(Display);
			spatial = eventEntity.get(Spatial);
			display.alpha = 0;
			spatial.x = shellApi.viewportWidth/2;
			spatial.y = shellApi.viewportHeight/2 + 50;
			spatial.scaleX = spatial.scaleY = .4;			
			
			setupSpectators();

			//startMatch(false);
			line_mc.alpha = 0;
			angle_mc.p0.visible = angle_mc.p1.visible = angle_mc.p2.visible = false;	
			SceneUtil.delay( this, .5, onSceneAnimateInComplete );
				
			super.shellApi.defaultCursor = ToolTipType.TARGET;
		}
		
		private function onSceneAnimateInComplete ():void {
			openInstructionsPopup()
		}
		
		override protected function onStartClicked (): void {
			_hud.setMode("game")
			startMatch(false);
		}
		
		override protected function onPracticeClicked (): void {
			_hud.setMode("practice")
			startMatch(true);
		}
		
		private function addButton(name:String, handler:Function):void
		{
		
			
			var newButton:Entity = ButtonCreator.createButtonEntity( super._hitContainer[name], this, null, null, [InteractionCreator.DOWN], ToolTipType.TARGET);
			var newInteraction:Interaction = newButton.get(Interaction);
			newInteraction.down.add(handler);
			
		}
		
		private function degreesToRadians(degrees:Number):Number {
			return degrees * Math.PI / 180;
		}
		
		private function handleButtonClicked(entity:Entity):void
		{
			
			var clickArr1:Array = [90,60,40];
			var clickArr2:Array = [1,1.5,2.25];
			
			if(clickCnt < 4){

				if (clickCnt < 3){
					angle_mc["p"+clickCnt].stop();		
					var fireNumber:Number = angle_mc["p"+clickCnt].currentFrame;
					if (fireNumber > clickArr1[clickCnt]) fireNumber = clickArr1[clickCnt] - (fireNumber - clickArr1[clickCnt]);
					angleArray[clickCnt] = fireNumber*clickArr2[clickCnt];
					
					fireangle = 0;
					for(var i:Number=0;i<=clickCnt;i++){
						fireangle += angleArray[i]
					}
					
		
					fireangle = fireangle/(clickCnt+1);
					TweenLite.to(line_mc, 1, {rotation:fireangle, alpha:1});
					
					clickCnt++;
					
					switch (clickCnt){
						case 1:
							super.shellApi.triggerEvent("angleClick1SFX");
						break;
						case 2:
							super.shellApi.triggerEvent("angleClick2SFX");
						break;
						case 3:
							super.shellApi.triggerEvent("angleClick3SFX");
						break;
					}
					
					if (clickCnt == 3){
						TweenLite.to(power_mc, 1, {x:320, y:470});
					}else{
						angle_mc["p"+clickCnt].visible = true;
					}
					
				}else{		
					super.shellApi.triggerEvent("angleClick4SFX");
					power_mc.p0.stop();
					power_mc.p1.stop();
					power_mc.p2.stop();
					
					var clickArr3:Array = [60,40,20];
					var heldTime:Number = 0;
					var curNum:Number;
							
					for(var j:Number=0;j<3;j++){
						
						if (j==0) curNum = power_mc.p0.currentFrame;
						if (j==1) curNum = power_mc.p1.currentFrame;
						if (j==2) curNum = power_mc.p2.currentFrame;
						
						if (curNum < clickArr3[j] && curNum > 1){
							heldTime += 1120 - (curNum*(clickArr3[j]/2));
						}else if (curNum > clickArr3[j] && curNum < (clickArr3[j]*2)){
							heldTime += 1120 - ((clickArr3[j]+(clickArr3[j] - curNum))*(clickArr3[j]/2));
						}else if (curNum == (clickArr3[j]*2)){
							heldTime += 1100;
						}else{
							heldTime += 1120;
						}

					}
					
					//heldTime = 3360;
	
					//heldTime = (heldTime/3)+200;
					if (fireangle != 45 && heldTime > 1000) heldTime-=50;
					var startSpeed:Number = heldTime/2;

					clickCnt++;
					CharUtils.getTimeline( player ).gotoAndPlay("start");
					Timeline(CharUtils.getTimeline(player)).handleLabel("launch", Command.create( startThrow, startSpeed ));
				}
			}
		}
		
		private function startMatch( isPractice:Boolean ):void {
			
			practicing = isPractice;			
			curRound = 1;
			bestScore = 0;

			startGame();
		}
		
		private function startGame():void {
			power_mc.p0.play();
			power_mc.p1.play();
			power_mc.p2.play();
			angle_mc.p0.play();
			angle_mc.p1.play();	
			angle_mc.p2.play();
			
			angle_mc.p0.visible = angle_mc.p1.visible = angle_mc.p2.visible = false;			
			angleArray = [0,0,0];
			power_mc.y = -175;
			line_mc.alpha = 0;
			line_mc.rotation = 45;
			angle_mc.alpha = 100;
			clickCnt = 0;
			angle_mc["p"+clickCnt].visible = true;

			SkinUtils.setSkinPart( player, SkinUtils.ITEM, 'shotput', false );
			CharUtils.setAnim(player,game.data.animation.entity.character.poptropolis.ShotputAnim,false);
			
			ShowHeatText(curRound);	

		}
		
		public function startThrow(startSpeed:Number):void{
			
			super.shellApi.triggerEvent("throwBallSFX");
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, 'empty', false );
			
			var playerSpatial:Spatial = player.get(Spatial);
			var playerEdge:Edge = player.get(Edge);
			
			ballEntity = EntityUtils.createMovingEntity(this, super.getAsset("ballClip.swf") as MovieClip, super._hitContainer);
			ballSpacial = ballEntity.get(Spatial);
			EntityUtils.position(ballEntity, playerSpatial.x + playerEdge.rectangle.left, playerSpatial.y + playerEdge.rectangle.top);			
			
			super.shellApi.camera.target = ballEntity.get(Spatial);
			
			//fireangle = 45;
			var radians:Number = degreesToRadians(fireangle);
			
	
			//figure out velocity vector
			var xSpeed:Number =startSpeed *  Math.sin(radians);
			var ySpeed:Number = (0 - startSpeed) * Math.cos(radians);				
			
			var motion:Motion = ballEntity.get(Motion);
			motion.velocity.x = xSpeed;
			motion.velocity.y = ySpeed;
			motion.acceleration.y = MotionUtils.GRAVITY;			
			
			super.addSystem( new ThresholdSystem() );
			var threshold:Threshold = new Threshold( "y", ">" )
			threshold.threshold = 700 + (curRound*10);
			threshold.entered.add( ballLanded );
			ballEntity.add( threshold );			

		}
		
		public function ballLanded():void{
			
			super.shellApi.triggerEvent("ballLandedSFX");
			
			var bx:Number = ballSpacial.x;
			var by:Number = ballSpacial.y;
			
			var ballGroundClip:MovieClip = MovieClip(super._hitContainer['ball'+curRound]); 		
		
			super.removeEntity( ballEntity )
			var ballGroundEntity:Entity = EntityUtils.createSpatialEntity(this, ballGroundClip, super._hitContainer);
			EntityUtils.position(ballGroundEntity, bx, by);	
			super.shellApi.camera.target = ballGroundEntity.get(Spatial);			
	
			eventTXT.x = bx;
			
			var playerScore:Number = Math.round(( bx - 643)/12.38);
			if (playerScore < 0) playerScore = 0;
			if (playerScore > bestScore){
				bestScore = playerScore;
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, newBestScore));				
			}
			
			ShowEventText(playerScore, curRound, bestScore);
		}
		
		protected override function setupSpectators():void
		{
			var emotions:Array = ["cheer", "ooh", "angry", "sad", "clap"];
			
			for(var i:int = 1; i <= 5; i++)
			{
				var clip:MovieClip = this._hitContainer["crowd" + i];
				clip.gotoAndStop(1);
				
				var skin:int = Utils.randInRange(1, 3);
				var integer:int = Utils.randInRange(0, emotions.length - 1);
				var emotion:String = emotions[integer];
				
				clip["head"]["expression"].gotoAndStop(integer + 1);
				clip["body"]["shirt"].gotoAndStop(Utils.randInRange(1, 5));
				clip["hair"].gotoAndStop(Utils.randInRange(1, 5));
				
				//Skin Color
				clip["feet"].gotoAndStop(skin);
				clip["hand1"].gotoAndStop(skin);
				clip["hand2"].gotoAndStop(skin);
				clip["head"]["head"].gotoAndStop(skin);
				clip["head"]["expression"]["eyeLids"].gotoAndStop(skin);
				
				var spectator:Entity = TimelineUtils.convertClip(clip, this);
				changeExpression(spectator, emotions, skin);
			}
		}
		
		public function newBestScore():void{
			super.shellApi.triggerEvent("beatScoreSFX");
		}
		
		public function ShowHeatText(curRound:int):void {
			if(practicing != true){
				switch(curRound) {
					case 1:
						heatTXT.attemptTXT.text = "First attempt";
						break;
					case 2:
						heatTXT.attemptTXT.text = "Second attempt";
						break;
					case 3:
						heatTXT.attemptTXT.text = "Final attempt";
						break;
				}
			} else {
				heatTXT.attemptTXT.text = "Practice attempt";
			}			
			
			//TweenLite.to(heatTXT, .3, {scaleX:1, scaleY:1, alpha:1, onComplete:HideHeatText});
			
			var tween:Tween = heatEntity.get(Tween);	
			var spatial:Spatial = heatEntity.get(Spatial);
			var display:Display = heatEntity.get(Display);
			display.alpha = 1;
			tween.to(spatial, .5, {scaleX:1, scaleY:1, onComplete:hideHeatText});
			
		}		
		
		private function hideHeatText():void
		{		
			// Delay 3 seconds
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, tweenHideHeat), "hideHeat");	
		}
		
		private function tweenHideHeat():void
		{
			var tween:Tween = heatEntity.get(Tween);
			var spatial:Spatial = heatEntity.get(Spatial);
			var display:Display = heatEntity.get(Display);
			tween.to(spatial, .3, {scaleX:.4, scaleY:.4});
			tween.to(display, .3, {alpha:0});	
		}

		
		public function ShowEventText(score:Number, attempt:Number, bestScore:Number):void {
			// set text
			if(score > 0){
				eventTXT.largeTXT.text = score + " Meters!";
			} else {
				eventTXT.largeTXT.text = "Fouled!";
			}
			if(practicing != true){
				switch(attempt) {
					case 1:
						eventTXT.attemptTXT.text = "First attempt:";
						break;
					case 2:
						eventTXT.attemptTXT.text = "Second attempt:";
						break;
					case 3:
						eventTXT.attemptTXT.text = "Final attempt:";
						break;
				}
			}else{
				eventTXT.attemptTXT.text = "Practice attempt:";
			}
			if (bestScore > 0) {
				eventTXT.farthestTXT.text = "Your farthest distance: " + bestScore + " Meters";
			} else {
				eventTXT.farthestTXT.text = "";
			}
			
			//eventTXT._y = -_root.camera._y + 210;
			eventTXT._visible = true;
			eventTXT._xscale = 40;
			eventTXT._yscale = 40;
			eventTXT._alpha = 100;
			
			//TweenLite.to(eventTXT, .3, {scaleX:1, scaleY:1, alpha:1, onComplete:hideEventText});			
			
			var tween:Tween = eventEntity.get(Tween);
			var spatial:Spatial = eventEntity.get(Spatial);
			var display:Display = eventEntity.get(Display);
			display.alpha = 1;
			tween.to(spatial, .5, {scaleX:1, scaleY:1, onComplete:hideEventText});
		}
		
		private function hideEventText():void
		{		
			// Delay 3 seconds
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, tweenHideEvent), "hideEvent");	
		}
		
		private function tweenHideEvent():void
		{
			var tween:Tween = eventEntity.get(Tween);
			var spatial:Spatial = eventEntity.get(Spatial);
			var display:Display = eventEntity.get(Display);
			tween.to(spatial, .3, {scaleX:.4, scaleY:.4});
			tween.to(display, .3, {alpha:0, onComplete:Reset});	
		}

		public function Reset():void{
			
			heatEntity.get(Display).alpha = 0;
			eventEntity.get(Display).alpha = 0;
			heatEntity.get(Spatial).scaleX = heatEntity.get(Spatial).scaleY = .4;
			eventEntity.get(Spatial).scaleX = eventEntity.get(Spatial).scaleY = .4;

			super.shellApi.camera.target = super.shellApi.player.get(Spatial);
			if (curRound < 3 && practicing != true){				
				curRound++;
				startGame ();
			}else{
				finishGame();
			}						
			
		}
		
		public function finishGame():void{
			power_mc.y = -175;			
			CharUtils.setAnim(player,Stand,false);
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, 'empty', false );
			if (practicing != true){
				angle_mc.alpha = 0;
				line_mc.alpha = 0;
				var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
				pop.setup();
			}else{
				openInstructionsPopup()
			}
		}
		
		public function dataLoaded( pop:Poptropolis ):void {
			
			pop.reportScore( Matches.SHOT_PUT, bestScore );
			
		}
		
		private function initHud (hud:ShotputHud):void {
			_hud.setMode("clear")
		}
		
		private function onExitPracticeClicked (): void {
			abortRace()
		}
		
		private function onStopRaceClicked (): void {
			abortRace()
		}
		
		private function abortRace ():void {
			super.shellApi.loadScene(game.scenes.poptropolis.shotput.Shotput);
		}
		
	}
}