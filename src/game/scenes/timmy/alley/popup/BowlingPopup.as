package game.scenes.timmy.alley.popup
{
	
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.OriginPoint;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.data.text.TextStyleData;
	import game.scenes.timmy.TimmyEvents;
	import game.scenes.viking.river.depthScale.DepthScale;
	import game.scenes.viking.river.depthScale.DepthScaleSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class BowlingPopup extends Popup
	{
		
		// pins with timelines
		private var pins:Vector.<Entity>;
		// ball rolls at these
		private var targets:Vector.<Entity>;
		// ball starts at these
		private var columns:Vector.<Entity>;
		// end popup when all shots are used
		private var remainingShots:Vector.<Entity>;
		
		private var leadPinIndeces:Array = [6,3,1,0,2,5,9];
		private var numPinColumns:int = 6;
		private var ballColumn:int;
		
		private var ball:Entity;
		private var clickArea:Entity;
		private var scoreBoard:Entity;
		
		private var ballMidX:Number = 480;		
		private var ballRightLimit:Number = 1075;
		private var ballLeftLimit:Number = 322;
		
		private var ballAimSpeed:Number = 2.0;
		
		private var score:int = 0;
		
		private var ballTargetX:Number;
		private var ballThrown:Boolean = false;
		
		private var _events:TimmyEvents;
		
		public var completeSignal:Signal;
		private var playerWon:Boolean;
		
		private const PIN_SOUND:String = SoundManager.EFFECTS_PATH + "bowling_pins_01.mp3";
		private const LAND_SOUND:String = SoundManager.EFFECTS_PATH + "wood_heavy_impact_01.mp3";
		private const ROLL_SOUND:String = SoundManager.EFFECTS_PATH + "bowling_ball_roll_01.mp3";
		private const MUSIC:String = SoundManager.MUSIC_PATH + "around_and_around.mp3";
		
		public function BowlingPopup(container:DisplayObjectContainer=null)
		{
			completeSignal = new Signal();
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;		
			this.pauseParent = true;
			super.groupPrefix = "scenes/timmy/alley/popup/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["bowling_popup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{				
			super.screen = super.getAsset("bowling_popup.swf", true) as MovieClip;
			
			var rect:Rectangle = new Rectangle(0,0,1382,680);
			this.letterbox(super.screen.content, rect, false);
			
			this.darkenAlpha = 0.85;
			super.loadCloseButton();
			super.loaded();
			
			setupPuzzle();
		}
		
		private function setupPuzzle():void
		{
			addSystem(new ThresholdSystem());
			addSystem(new DepthScaleSystem());
			
			// ball moves back and forth, click anywhere to throw, roll down path, hit pins based on x value of ball, win after so many points
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				ball = BitmapTimelineCreator.createBitmapTimeline(screen.content["ball"],true,true,null,PerformanceUtils.defaultBitmapQuality + 0.1);
				addEntity(ball);
				ball.add(new Motion());
			}
			else{
				ball = EntityUtils.createMovingTimelineEntity(this,screen.content["ball"]);
			}
			ball.add(new Id("ball"));
			ball.add(new DepthScale(200,650,0.2,1.0));
			ballMidX = ball.get(Spatial).x;
			ball.get(Spatial).x = ballLeftLimit;
			ball.add(new OriginPoint(ball.get(Spatial).x,ball.get(Spatial).y,ball.get(Spatial).rotation));
			moveRight();
			
			remainingShots = new Vector.<Entity>();
			var clip:MovieClip;
			for (var x:int = 0; x < 4; x++) 
			{
				clip = screen.content["shot"+x];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality + 0.1);
				}
				var shot:Entity = EntityUtils.createSpatialEntity(this,clip);
				remainingShots.push(shot);
			}
			
			clickArea = EntityUtils.createSpatialEntity(this, screen.content["bounds"]);
			var inter:Interaction =  InteractionCreator.addToEntity(clickArea,[InteractionCreator.CLICK]);
			inter.click.add(throwBall);
			ToolTipCreator.addToEntity(clickArea);
			
			var styleData:TextStyleData = shellApi.textManager.getStyleData( TextStyleData.UI, "digitalgreen" );	
			styleData.size = 38;
			var textfield:TextField = new TextField();
			textfield.alwaysShowSelection = false;
			textfield.selectable = false;
			textfield.text = "0";
			textfield.width = 60;
			textfield.height = 60;
			TextUtils.applyStyle(styleData,textfield);
			textfield.embedFonts = true;
			textfield.x = screen.content["pScore"].x;
			textfield.y = screen.content["pScore"].y;
			scoreBoard = EntityUtils.createSpatialEntity(this ,textfield, screen.content);			
			updateScoreText();
			
			columns = new Vector.<Entity>();
			for (var j:int = 0; j < 7; j++) 
			{
				var column:Entity = EntityUtils.createSpatialEntity(this,screen.content["column"+j]);
				column.get(Display).visible = false;
				columns.push(column);
			}
			
			targets = new Vector.<Entity>();
			for (var l:int = 0; l < 7; l++) 
			{
				var target:Entity = EntityUtils.createSpatialEntity(this,screen.content["target"+l]);
				target.get(Display).visible = false;
				targets.push(target);
			}
			
			pins = new Vector.<Entity>();
			var pin:Entity;	
			var seq:BitmapSequence;
			for (var i:int = 1; i <= 10; i++) 
			{
				clip = screen.content["pin"+i];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					if(!seq){
						seq = BitmapTimelineCreator.createSequence(clip,true,PerformanceUtils.defaultBitmapQuality + 0.2);
					}
					pin = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,seq,PerformanceUtils.defaultBitmapQuality + 0.2);
					addEntity(pin);
					pin.add(new Motion());
				}
				else{
					pin = EntityUtils.createMovingTimelineEntity(this,clip);
				}
				pin.add(new Id("pin"+i));
				pin.add(new OriginPoint(pin.get(Spatial).x,pin.get(Spatial).y,pin.get(Spatial).rotation));
				pin.add(new BowlingPin());
				pins.push(pin);
			}
			
			shellApi.triggerEvent(_events.ATTEMPTED_BOWLING_GAME, true);
			
			startMusic();
			
			setGame();
			startGame();
		}
		
		private function startMusic():void
		{
			shellApi.triggerEvent("bowl_start");
			//			AudioUtils.stop(parent,null,SoundModifier.MUSIC);
			//			var audio:Audio = AudioUtils.getAudio(parent);
			//			audio.play(MUSIC, true, null, 1);
			//			audio.fade(MUSIC, 0.6, NaN, 0, SoundModifier.MUSIC);
		}
		
		private function moveRight(...p):void
		{
			TweenUtils.entityTo(ball, Spatial, ballAimSpeed, {x:ballRightLimit, ease:Sine.easeInOut, onComplete:moveLeft});
		}
		
		private function moveLeft(...p):void
		{
			TweenUtils.entityTo(ball, Spatial, ballAimSpeed, {x:ballLeftLimit, ease:Sine.easeInOut, onComplete:moveRight});
		}
		
		private function stopMove(...p):void
		{
			var motion:Motion = ball.get(Motion);
			motion.zeroMotion();
			Tween(ball.get(Tween)).killAll();
			//var thresh:Threshold = ball.get(Threshold);
			//thresh.entered.removeAll();
		}
		
		private function hitPins(...p):void
		{
			// kill motion, fade ball, animate pins
			var motion:Motion = ball.get(Motion);
			motion.zeroMotion("y");
			motion.velocity.y = -50;
			TweenUtils.entityTo(ball,Display,1.0,{alpha:0, onComplete:delayReset});
			
			// SOUND
			AudioUtils.stop(this, ROLL_SOUND,"roll");
			AudioUtils.play(this, PIN_SOUND, 1.2);
			
			var headPin:Entity = pins[leadPinIndeces[ballColumn]];
			var childs:Children = headPin.get(Children);
			var targetPins:Vector.<Entity> = new Vector.<Entity>();
			if(childs){
				targetPins = childs.children.slice(0,childs.children.length);
				targetPins.unshift(headPin);
			}
			// hit pins in SOI
			var func:Function;
			for(var j:int=0; j < targetPins.length; j++){
				if(j == targetPins.length -1){
					func = Command.create(hitPin, targetPins[j], true);
				}
				else{
					func = Command.create(hitPin, targetPins[j]);
				}
				SceneUtil.addTimedEvent(this, new TimedEvent(0.05+(0.05*j),1,func));
				score ++;
				ballAimSpeed -= 0.04;
			}
		}
		
		private function hitPin(pin:Entity, last:Boolean = false):void 
		{	
			var bowl:BowlingPin = pin.get(BowlingPin);
			bowl.knockedOver = true;
			Timeline(pin.get(Timeline)).gotoAndPlay("start");
			if(last){
				updateScoreText();
			}
		}
		
		
		private function setGame():void
		{
			for (var i:int=1; i<=10; i++){
				OriginPoint(pins[i-1].get(OriginPoint)).applyToSpatial(pins[i-1].get(Spatial));
			}
			
			pins[0].add(new Children());//1 STRIKE
			Children(pins[0].get(Children)).children.push(pins[1],pins[2],pins[3],pins[4],pins[5],pins[6],pins[7],pins[8],pins[9]);
			pins[1].add(new Children());//2
			Children(pins[1].get(Children)).children.push(pins[3],pins[4],pins[7]);
			pins[2].add(new Children());//3
			Children(pins[2].get(Children)).children.push(pins[4],pins[5],pins[8]);
			pins[3].add(new Children());//4
			Children(pins[3].get(Children)).children.push(pins[6],pins[7]);
			pins[4].add(new Children());//5
			Children(pins[4].get(Children)).children.push(pins[7],pins[8]);
			pins[5].add(new Children());//6
			Children(pins[5].get(Children)).children.push(pins[8],pins[9]);
			// back row has no children, still needs componenet
			pins[6].add(new Children());//7
			pins[7].add(new Children());//8
			pins[8].add(new Children());//9
			pins[9].add(new Children());//10
		}
		
		private function delayReset(...p):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(2.0,1,checkForReset));
		}
		
		private function checkForReset(...p):void
		{	
			if(remainingShots.length > 0){
				// fade pins & ball back in
				resetPins();
				resetBall();
			}
			else{
				// end game
				deliverResult();
			}
		}
		
		private function deliverResult():void
		{
			if(score >= 30)
			{
				playerWon = true;
				shellApi.removeEvent(_events.ATTEMPTED_BOWLING_GAME);	
			}
			SceneUtil.lockInput(this,false);
			this.popupRemoved.add(Command.create(completeSignal.dispatch,playerWon,score));
			AudioUtils.stop(this, MUSIC, "bgm");
			close(true);
		}
		
		private function resetPins():void 
		{
			for (var i:int=0; i<10; i++) {
				OriginPoint(pins[i].get(OriginPoint)).applyToSpatial(pins[i].get(Spatial));
				var bowl:BowlingPin = pins[i].get(BowlingPin);
				if(bowl.knockedOver){
					bowl.knockedOver = false;
					Timeline(pins[i].get(Timeline)).gotoAndStop("start");
					Display(pins[i].get(Display)).alpha = 0;
					TweenUtils.entityTo(pins[i],Display,1.6,{alpha:1});
				}
			}
		}
		
		private function resetBall():void 
		{
			var motion:Motion = ball.get(Motion);
			motion.zeroMotion("y");
			var spatial:Spatial = ball.get(Spatial);
			OriginPoint(ball.get(OriginPoint)).applyToSpatial(spatial);
			TweenUtils.entityTo(ball,Display,1.7,{alpha:1, onComplete:startGame});
			Timeline(ball.get(Timeline)).gotoAndStop("start");
		}
		
		private function updateScoreText():void
		{
			if(scoreBoard){
				var tf:TextField = scoreBoard.get(Display).displayObject as TextField; 
				tf.text	= score.toString();
			}
		}
		
		private function startGame():void 
		{	
			ballThrown = false;
			SceneUtil.lockInput(this, false);
			moveRight();
		}
		
		private function throwBall(...p):void 
		{
			if(!ballThrown){
				AudioUtils.play(this, LAND_SOUND, 1.5);
				AudioUtils.play(this, ROLL_SOUND, 1.5, true,null,"roll");
				stopMove();
				SceneUtil.lockInput(this, true);
				ballThrown = true;
				ballColumn = getPinColumn(ball.get(Spatial).x);
				
				var motion:Motion = ball.get(Motion);
				motion.zeroMotion();
				var spatial:Spatial = ball.get(Spatial);
				
				var target:Entity = targets[ballColumn];
				var targetSpatial:Spatial = target.get(Spatial);
				
				TweenUtils.entityTo(ball, Spatial, 1.5, {x:targetSpatial.x, y:targetSpatial.y, onComplete:hitPins});
				
				Timeline(ball.get(Timeline)).gotoAndPlay("roll");
				// remove shot chance
				var removedShot:Entity = remainingShots.pop();
				this.removeEntity(removedShot);
			}
		}
		
		// find closest column of pins
		private function getPinColumn(ballX:Number):uint {
			var motion:Motion = ball.get(Motion);
			var spatial:Spatial = ball.get(Spatial);
			
			var column:uint = 3;
			var shortestDist:Number = 1000;
			var closestColumn:Entity;
			for (var i:int = 0; i < columns.length; i++) 
			{
				var cur:Spatial = columns[i].get(Spatial);
				var dist:Number = Math.abs(spatial.x - cur.x);
				if(shortestDist > dist)
				{
					shortestDist = dist;
					closestColumn = columns[i];
					column = i;
				}
			}
			
			return column;
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			super.close(removeOnClose,onClosedHandler);
		}
		
		
		
	}
}