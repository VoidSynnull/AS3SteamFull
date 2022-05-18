package game.scenes.prison.metalShop.popups
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.entity.VariableTimeline;
	import game.components.motion.FollowTarget;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMasterVariable;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.text.TextStyleData;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.scenes.prison.PrisonEvents;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.Popup;
	import game.util.ArrayUtils;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class LicensePlateGame extends Popup
	{
		private var _events:PrisonEvents;
		
		public var completeSignal:Signal;
		
		private var onePlateMade:Boolean = false;
		private var gameStarted:Boolean = false;
		private var gameComplete:Boolean = false;
		private var overHeated:Boolean = false;
		
		private var score:int = 0;
		private var quota:int = 5;	
		private var overheatQuota:int = 7;
		private var daysInPrison:int = 0;
		
		private var timelimit:Number = 90;
		private var plateSlideSpeed:Number = 100;
		
		private var timerDelay:TimedEvent;
		private var timeLeft:int;
		
		private var belt:Entity;
		private var light:Entity;
		private var gauge:Entity;
		private var gaugeHand:Entity;
		private var gaugePipe:Entity;
		private var timer:Entity;
		private var quotaText:Entity;
		private var plateDisplay:Entity;
		private var stamper:Entity;
		private var backGround:Entity;
		private var foreGround:Entity;
		private var leadingPlate:Entity;

		private var buttons:Vector.<Entity>;
		private var sparks:Vector.<Entity>;
		private var platesVect:Vector.<Entity>;
		private var currPlate:int = 0;
		
		private var endEvent:String;
		
		private const PLATES:String = "plates";
		private const STAMPSYTLE:String = "plate";
		private const UISYTLE:String = "nixie";		
		
		public function LicensePlateGame(container:DisplayObjectContainer=null, currentPlates:int = 0)
		{
			completeSignal = new Signal();
			this.score = currentPlates;
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
			super.groupPrefix = "scenes/prison/metalShop/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["licensePlateGame.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{				
			super.screen = super.getAsset("licensePlateGame.swf", true) as MovieClip;
			
			daysInPrison = shellApi.getUserField(_events.DAYS_IN_PRISON_FIELD, shellApi.island);
			
			super.letterbox(super.screen.content, new Rectangle(0,0,960,640));
			
			this.darkenAlpha = 0.84;
			super.loadCloseButton();
			super.loaded();
			
			SceneUtil.lockInput(this, true);
			
			this.addSystem(new ThresholdSystem());
			this.addSystem(new ShakeMotionSystem());
			this.addSystem(new VariableTimelineSystem());
			
			applyDifficultyScale();
			
			setupButtons();
			setupUI();
			
			setupLicensePlates();
			if(!shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE)){
				// open guide popup on top of this popup, and then start timer and stuff
				startGuidePopup();
			}else{
				setTimer(4, startGame);
			}
		}
		
		private function startGuidePopup():void
		{
			// TODO: learn to play scrub!
			var popup:LicensePlateGuide = this.addChildGroup(new LicensePlateGuide(container)) as LicensePlateGuide;
			popup.closeClicked.addOnce(guideComplete);
		}
		
		private function guideComplete(...p):void
		{
			setTimer(4, startGame);
		}
		
		private function applyDifficultyScale(...p):void
		{
			//timelimit = 65;
			//plateSlideSpeed = 120;
			// today's quota
			if(shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE)){
				quota = 5;
			}
			else{
				quota = 3;
				timeLeft = 60;
			}
		}
		
		private function setupButtons():void
		{
			buttons = new Vector.<Entity>();
			var inter:Interaction;
			var tf:Entity;
			for (var i:int = 0; i < 8; i++) 
			{
				var clip:MovieClip = super.screen.content["button"+i]
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapUtils.convertContainer(clip["bg"], 1);
				}
				var buttonAnim:Entity = EntityUtils.createSpatialEntity(this, clip);
				buttonAnim.add(new Id("button"+i));
				inter = InteractionCreator.addToEntity(buttonAnim,[InteractionCreator.CLICK]);
				inter.click.add(pressedButton);
				ToolTipCreator.addToEntity(buttonAnim);
				tf = makeTextField(buttonAnim, " ", null, 80, 80,"tf",new Point(0,0), 80);
				tf.add(new Id("tf"));
				EntityUtils.addParentChild(tf, buttonAnim);
				buttons.push(buttonAnim);
			}
		}
		
		private function makeTextField(parent:Entity, text:String, styleId:String, width:Number = 80, height:Number = 100, tfName:String = "tf", offset:Point = null, size:int = 52):Entity
		{		
			var parentDisplay:MovieClip = Display(parent.get(Display)).displayObject;
			var textfield:TextField = parentDisplay[tfName];
			//change the font style
			if(styleId != null){
				var styleData:TextStyleData = shellApi.textManager.getStyleData( TextStyleData.UI, styleId);	
				styleData.size = size;
				TextUtils.applyStyle(styleData,textfield);
			}
			textfield.alwaysShowSelection = false;
			textfield.selectable = false;
			
			textfield.text = text;
			if(width){
				textfield.width = width;
			}
			if(height){
				textfield.height = height;
			}
			textfield.embedFonts = true;
			if(offset){
				textfield.x += offset.x;
				textfield.y += offset.y;
			}
			var tfEntity:Entity = EntityUtils.createSpatialEntity(this, textfield, parentDisplay);			
			return tfEntity;
		}
		
		private function pressedButton(button:Entity, ...p):void
		{
			if(!gameComplete && gameStarted){
				var up:Function = Command.create(TweenUtils.entityTo,button,Spatial, 0.2,{scale:1.0});
				TweenUtils.entityTo(button,Spatial, 0.2,{scale:0.93, onComplete:up});
				buttonSound();
				// apply the text on button to leading blank plate's current blank textbox
				var buttonTf:Entity =  Children(button.get(Children)).getChildByName("tf");
				var buttonText:TextField = Display(buttonTf.get(Display)).displayObject;
				var license:LicensePlate = leadingPlate.get(LicensePlate);
				if(license.pushInputText(buttonText.text)){
					stampPlate(license.textPos-1);
					if(license.plateFull){
						SceneUtil.delay(this, 0.5, speedUpPlate);
					}
				}
			}
		}
		
		private function speedUpPlate(...p):void
		{
			// plate is full, move it off screen faster
			Motion(leadingPlate.get(Motion)).velocity.x = -plateSlideSpeed * 2.55;
			TimelineMasterVariable(belt.get(TimelineMasterVariable)).frameRate = 38;
		}
		
		private function stampPlate(i:int=0):void
		{
			// position and animate stamper on top of current blank spot on plate
			var targ:Point = EntityUtils.getPosition(leadingPlate);
			EntityUtils.position(stamper, targ.x, targ.y);
			var tl:Timeline = stamper.get(Timeline)
			tl.gotoAndPlay("extend");
			tl.handleLabel("impact",stampSound);
			tl.handleLabel("retract",updatePlateText);
			var follow:FollowTarget = new FollowTarget(leadingPlate.get(Spatial),1);
			// find offset based on plate's current character
			follow.offset = new Point(0,0);
			switch(i)
			{
				case 0:
				{
					follow.offset.x = -100;
					break;
				}
				case 1:
				{
					follow.offset.x = -50;
					break;
				}
				case 2:
				{
					follow.offset.x = 2;
					break;
				}
				case 3:
				{
					follow.offset.x = 52;
					break;
				}	
				case 4:
				{
					follow.offset.x = 102;
					break;
				}
			}
			stamper.add(follow);
		}	
		
		private function updatePlateText(...p):void
		{
			var childs:Children = leadingPlate.get(Children);
			var license:LicensePlate = leadingPlate.get(LicensePlate);
			for (var i:int = 0; i < 5; i++) 
			{
				var child:Entity = childs.getChildByName("tf"+i);
				if(child){
					var display:Display = child.get(Display);
					display.displayObject.text = license.getTextAt(i);
				}
			}
		}
		
		private function buttonSound(...p):void
		{
			// SOUND
			AudioUtils.play(this,SoundManager.EFFECTS_PATH +"switch_03.mp3", 1.0);
		}
		private function stampSound(...p):void
		{
			// SOUND
			AudioUtils.play(this,SoundManager.EFFECTS_PATH +"machine_impact_01.mp3", 1.0);
		}
		
		private function setupUI():void
		{
			this.addSystem(new VariableTimelineSystem());
			var clip:MovieClip = super.screen.content["belt"];
			// belt, lights,and timer animations, score board
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality + 1.0);
			belt = EntityUtils.createMovingTimelineEntity( this, clip, null,false, 16);
			
			clip = super.screen.content["lights"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality + 1.0);
			light = EntityUtils.createMovingTimelineEntity( this, clip);
			
			clip = super.screen.content["gauge"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality + 1.0);
			gauge = EntityUtils.createSpatialEntity(this, clip);
			gaugeHand = EntityUtils.createSpatialEntity(this, clip["hand"]);
			EntityUtils.addParentChild(gaugeHand,gauge);
			gaugePipe = EntityUtils.createMovingTimelineEntity(this, clip["pipe"]);
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-3, 0, 3, 0));
			shake.onInterval = 1.9;
			shake.offInterval = 1.75;
			shake.shaking = false;
			shake.active = false;
			gauge.add(shake);
			gauge.add(new SpatialAddition());
			
			var tf:Entity;
			timer = EntityUtils.createSpatialEntity(this, super.screen.content["timer"]);
			var convString:Array = String("0003").split("");
			for (var j:int = 0; j < convString.length; j++) 
			{
				tf = makeTextField(timer, convString[j], null,80,100,"tf"+j,new Point(-21,0));
				tf.add(new Id("tf"+j));
				EntityUtils.addParentChild(tf,timer);
			}
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(timer));
			
			clip = super.screen.content["quota"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip["bg"],PerformanceUtils.defaultBitmapQuality  + 1.0);
			quotaText = EntityUtils.createSpatialEntity(this, clip);
			if(quota<10){
				convString = String("0"+score+"0"+quota).split("");
			}else{
				convString = String("0"+score+quota).split("");
			}
			for (var k:int = 0; k < convString.length; k++) 
			{
				tf = makeTextField(quotaText, convString[k], null, 80, 100, "tf"+k, new Point(-21,0));
				tf.add(new Id("tf"+k));
				EntityUtils.addParentChild(tf, quotaText);
			}
			
			clip = super.screen.content["plateDisplay"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip["bg"],PerformanceUtils.defaultBitmapQuality + 1.0);
			plateDisplay = EntityUtils.createSpatialEntity(this, clip);
			plateDisplay.add(new Sleep(false,true));
			for (var i:int = 0; i < 5; i++) 
			{
				tf = makeTextField(plateDisplay, " ", null, 80, 108, "tf"+i, new Point(-20,0));
				tf.add(new Id("tf"+i));
				EntityUtils.addParentChild(tf,plateDisplay);
			}
			clip = super.screen.content["stamper"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				stamper = EntityUtils.createMovingTimelineEntity(this, clip);
				stamper = BitmapTimelineCreator.convertToBitmapTimeline(stamper, clip, true, null, PerformanceUtils.defaultBitmapQuality + 1.0);
			}
			else{
				stamper = EntityUtils.createMovingTimelineEntity(this, clip);
			}
			stamper.add(new Sleep(false,true));
			
			// layers
			clip = super.screen.content["FG"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality + 1.0);
			foreGround = EntityUtils.createSpatialEntity(this, clip);
			clip = super.screen.content["BG"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality + 1.0);
			backGround = EntityUtils.createSpatialEntity(this, clip);
			
			// overheat sparks
			sparks = new Vector.<Entity>();
			for (var l:int = 0; l < 4; l++) 
			{
				var spark:Entity = EntityUtils.createMovingTimelineEntity(this, super.screen.content["spark"+l]);
				sparks.push(spark);
			}
		}
		
		private function setTimer(time:int, complete:Function):void
		{
			timeLeft = time;
			// start ticking timer box, execute function at end
			timerDelay = new TimedEvent(1,0,Command.create(tickTimer,time,complete));
			SceneUtil.addTimedEvent(this, timerDelay);
		}
		
		private function tickTimer(time:Number, complete:Function):void
		{
			timeLeft -= 1;
			// update timer text
			var children:Children = timer.get(Children);
			var tfEnt:Entity;
			var tf:TextField;
			var convString:Array;
			if(timeLeft < 10){
				convString = String("000"+timeLeft).split("");
			}
			else if(timeLeft > 0){
				if(timeLeft == 60){
					convString = String("0100").split("");
				}
				else if(timeLeft > 60){
					var tResult:int = (timeLeft-60);
					if(tResult < 10){
						convString = String("010"+ tResult).split("");
					}else{
						convString = String("01"+ tResult).split("");
					}
				}
				else{
					convString = String("00"+timeLeft).split("");
				}
			}else{
				convString = String("0000").split("");
			}
			for (var i:int = 0; i < convString.length; i++) 
			{
				tfEnt = children.getChildByName("tf"+i);
				if(tfEnt){
					tf = tfEnt.get(Display).displayObject;
					tf.text = convString[i];
				}
			}
			if(timeLeft <= 0){
				timeLeft = 0;
				timerDelay.stop();
				complete();
				//SOUND
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"countdown_01.mp3",0.8);
			}else{
				// warning sound at last 5 seconds
				if(timeLeft <= 5){
					//SOUND
					AudioUtils.play(this, SoundManager.EFFECTS_PATH+"countdown_02.mp3",0.8);
				}
			}
		}
		
		private function setupLicensePlates():void
		{				
			platesVect = new Vector.<Entity>();
			// generate plates with random string to emboss on plates
			for (var i:int = 0; i < quota; i++)
			{
				this.loadFile("licensePlate.swf", Command.create(setupLicensePlate, i));
			}
			// when plate reaches right end, check 'spelling' of plate, failed plates are lost, success plates are added to score
			// continue until today's quota has been reached, timer runs out, or overheat; tally up score, close popup
		}
		
		private function setupLicensePlate(plateAsset:MovieClip, i:int = 0):void
		{
			var clip:MovieClip = plateAsset;
			clip = super.screen.content.addChild(clip) as MovieClip;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
				BitmapUtils.convertContainer(clip["bg"],PerformanceUtils.defaultBitmapQuality + 1.0);
			var plate:Entity = EntityUtils.createMovingEntity(this, clip);
			plate.add(new Sleep(false,true));
			//text
			for (var j:int = 0; j < 5; j++)
			{
				var tfEnt:Entity = makeTextField(plate, " ", null, 150, 100, "tf"+j, new Point(-54,0));
				tfEnt.add(new Id("tf"+j));
				EntityUtils.addParentChild(tfEnt, plate);
			}
			var licensePlate:LicensePlate = new LicensePlate();
			licensePlate.targetText = generatePlate(5);
			plate.add(licensePlate);
			Spatial(plate.get(Spatial)).x = 1200;
			Spatial(plate.get(Spatial)).y = 505;
			
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(plate));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(belt));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(backGround));
			platesVect.push(plate);
			if(i >= quota-1){
				//ready up
				loadFinished();
			}
		}
		
		private function loadFinished():void
		{
			// allow game start, enable start button
			SceneUtil.lockInput(this, false);
			currPlate = 0;
			leadingPlate = platesVect[currPlate];
		}
		
		// generate plate string using consonants and numbers, no vowels to avoid offensive strings... i hope
		private function generatePlate(length:int = 5):String{
			var chars:String = "BCDFGHJKLMNPQRSTVWXYZ0123456789";
			var numChars:int = chars.length - 1;
			var plateText:String = "";
			
			for (var i:int = 0; i < length; i++){
				plateText += chars.charAt(GeomUtils.randomInt(0,numChars));
			}
			return plateText;
		}
		
		private function startGame(...p):void
		{
			if(!gameStarted){	
				// display target plate text, update button text to match, update ui elements as needed
				// slide each blank onto belt from left, start checking for button presses, apply presses to leading plate
				gameStarted = true;
				launchPlate(leadingPlate);
				
				setTimer(timelimit, Command.create(completeGame,"timeOut"));
			}
		}
		
		// sets a plate moving and updates text prompts to match plate
		private function launchPlate(plate:Entity):void
		{
			if(!gameComplete){
				SceneUtil.lockInput(this, false);
				Sleep(plate.get(Sleep)).sleeping =  false;
				Spatial(plate.get(Spatial)).x = 1200;
				Motion(plate.get(Motion)).velocity.x = -plateSlideSpeed;
				if(!Timeline(belt.get(Timeline)).playing){
					Timeline(belt.get(Timeline)).play();
					//SOUND
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "treadmill_servo_01_loop.mp3", 0.55, true);
				}
				TimelineMasterVariable(belt.get(TimelineMasterVariable)).frameRate = 16;
				var license:LicensePlate = plate.get(LicensePlate);
				// set display for target plate's text
				// shuffle target plate string with some extra random characters, apply to button's text
				var buttonString:String = license.targetText + generatePlate(3);
				var textArray:Array = buttonString.split("");
				ArrayUtils.shuffleArray(textArray);
				for (var i:int = 0; i < buttons.length; i++) 
				{
					var tfEnt:Entity = Children(buttons[i].get(Children)).getChildByName("tf");
					var buttonText:TextField = tfEnt.get(Display).displayObject;
					buttonText.text = textArray[i];
				}
				// add threshold to check for plate entering evaulator
				var thresh:Threshold = new Threshold("x","<");
				thresh.threshold = -155;
				thresh.entered.addOnce(Command.create(scorePlate,plate));
				plate.add(thresh);
				
				updatePlateDisplay(license.targetText);
				enterPlateDisplay();
			}else{
				Motion(plate.get(Motion)).zeroMotion();
			}
		}
		
		private function enterPlateDisplay(onComplete:Function = null):void
		{
			// move template into view
			EntityUtils.position(plateDisplay, 435, -32);
			TweenUtils.entityTo(plateDisplay,Spatial,0.7,{y:140, ease:Bounce.easeOut, onComplete:onComplete});
			// SOUND
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"metal_hit_01.mp3",1.4);
		}
		
		private function exitPlateDisplay(onComplete:Function = null):void
		{
			// move template out of view
			EntityUtils.position(plateDisplay, 435, 140);
			TweenUtils.entityTo(plateDisplay,Spatial,0.7,{y:308, ease:Bounce.easeOut, onComplete:onComplete});
			// SOUND
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"metal_hit_01.mp3",1.4);
		}
		
		private function updatePlateDisplay(plateText:String):void
		{
			var textArray:Array = plateText.split("");
			var childs:Children = plateDisplay.get(Children);	
			for (var i:int = 0; i < textArray.length; i++) 
			{
				var ch:Entity = childs.getChildByName("tf"+i);
				if(ch){
					var childDisp:Display = ch.get(Display);
					childDisp.displayObject.text = textArray[i];
				}
			}
		}
		
		// compare target text to current text, blink green and give point if match, else blink red, no points!
		private function scorePlate(plate:Entity):void
		{
			SceneUtil.lockInput(this);
			var license:LicensePlate = plate.get(LicensePlate);
			var targetAsArray:Array = license.targetText.split("");
			var matches:int = 0;
			for (var i:int = 0; i < targetAsArray.length; i++) 
			{
				if(targetAsArray[i] == license.getTextAt(i)){
					matches++;
				}
			}
			if(matches == targetAsArray.length){
				grantPoint(plate);
			}
			else{
				denyPoint(plate);
			}
			// set next plate moving
			if(currPlate + 1 < platesVect.length){	
				currPlate++;
				Sleep(leadingPlate.get(Sleep)).sleeping =  true;
				leadingPlate = platesVect[currPlate];
				exitPlateDisplay(Command.create(launchPlate,leadingPlate));
			}
			else{
				// regenerate strings and loop plates back to plate 0
				resetPlates();
				exitPlateDisplay(Command.create(launchPlate,leadingPlate));
			}
		}
		
		private function resetPlates():void
		{
			currPlate = 0;
			var licensePlate:LicensePlate;
			var plate:Entity;
			for (var i:int = 0; i < platesVect.length; i++) 
			{
				plate = platesVect[i];
				plate.add(new Motion());
				plate.get(Spatial).x = 1200;
				licensePlate = plate.get(LicensePlate);
				licensePlate.targetText = generatePlate(5);
				licensePlate.resetInput();
				var childs:Children = plate.get(Children);
				for (var j:int = 0; j < childs.children.length; j++) 
				{
					var ch:Entity = childs.getChildByName("tf"+j);
					if(ch){
						var childDisp:Display = ch.get(Display);
						TextField(childDisp.displayObject).text = " ";
					}
				}
			}
			leadingPlate = platesVect[0];
		}
		
		private function grantPoint(plate:Entity):void
		{
			Timeline(light.get(Timeline)).gotoAndPlay("greenFlash");
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + "points_ping_02e.mp3",1.0);
			exitPlateDisplay(addScore);
		}
		
		private function denyPoint(plate:Entity):void
		{
			Timeline(light.get(Timeline)).gotoAndPlay("redFlash");
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + "alarm_04.mp3",1.0);
			exitPlateDisplay(null);
		}
		
		private function completeGame(endEvent:String):void
		{
			this.endEvent = endEvent;
			SceneUtil.lockInput(this, true);
			// flash lights, clear display text and indicate finish
			var TL:Timeline = Timeline(light.get(Timeline));
			if(endEvent=="timeOut"){
				//SOUND
				AudioUtils.play(this,SoundManager.EFFECTS_PATH + "achievement_02.mp3",0.8);
				TL.gotoAndPlay("flashRed");
				TL.handleLabel("redEnd",Command.create(TL.gotoAndPlay,"flashRed"));
			}
			else if(endEvent=="quotaMet"){
				//SOUND
				AudioUtils.play(this,SoundManager.EFFECTS_PATH + "achievement_02.mp3",0.8);
				TL.gotoAndPlay("flashGreen");
				TL.handleLabel("greenEnd",Command.create(TL.gotoAndPlay,"flashGreen"));
			}
			else if(endEvent=="overHeat"){
				//SOUND
				AudioUtils.play(this,SoundManager.EFFECTS_PATH + "alarm_04.mp3",1.0);
				TL.gotoAndPlay("flashRed");
				TL.handleLabel("redEnd",Command.create(TL.gotoAndPlay,"flashRed"));
			}else{
				//SOUND
				AudioUtils.play(this,SoundManager.EFFECTS_PATH + "alarm_04.mp3",1.0);
				TL.gotoAndPlay("flashRed");
				TL.handleLabel("redEnd",Command.create(TL.gotoAndPlay,"flashRed"));
			}
			Timeline(belt.get(Timeline)).stop();
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "treadmill_servo_01_loop.mp3");
			for each (var plate:Entity in platesVect) 
			{
				Motion(plate.get(Motion)).zeroMotion();
			}
			SceneUtil.delay(this, 2.5, close);
		}
		
		private function addScore(...p):void
		{
			onePlateMade = true;
			score++;
			var children:Children = quotaText.get(Children);
			var tfEnt:Entity;
			var tf:TextField;
			var convString:Array;
			// add zeros for appearance
			if(score < 10){
				if(quota<10){
					convString = String("0" + score + "0" + quota).split("");
				}else{
					convString = String("0" + score + quota).split("");
				}
			}else{
				if(quota<10){
					convString = String(score + "0" + quota).split("");
				}else{
					convString = String(score + quota).split("");
				}
			}
			for (var i:int = 0; i < convString.length; i++) 
			{
				tfEnt = children.getChildByName("tf"+i);
				if(tfEnt){
					tf = tfEnt.get(Display).displayObject;
					tf.text = convString[i];
				}
			}
			// overheat indicator
			increaseTemperature();
			if(!shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE) && score >= quota){
				//quota met				
				timeLeft = 0;
				timerDelay.stop();
				completeGame("quotaMet");
			}
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			SceneUtil.lockInput(this,false);
			this.popupRemoved.add(Command.create(completeSignal.dispatch, onePlateMade, score, endEvent)); // dispatch sucess level
			//AudioUtils.stop(this, MUSIC, "bgm");
			super.close(true, onClosedHandler);
		}
		
		
		private function increaseTemperature():void
		{
			// raise gauge level every sucess, overheat when 180 has been exceeded
			// SOUND
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "air_shot_03.mp3", 1.0);
			var spat:Spatial = Spatial(gaugeHand.get(Spatial));
			TweenUtils.entityTo(gaugeHand, Spatial, 0.8, {rotation:spat.rotation + (180-5)/(overheatQuota), ease:Quad.easeInOut, onComplete:checkOverheat});
		}
		
		private function checkOverheat():void
		{
			// check overheat and shake stuff
			var spat:Spatial = Spatial(gaugeHand.get(Spatial));
			if(spat.rotation >= 180){
				// OVERHEAT
				var TL:Timeline = Timeline(light.get(Timeline))
				TL.gotoAndPlay("flashRed");
				TL.handleLabel("redEnd",Command.create(TL.gotoAndPlay,"flashRed"));
				TL = belt.get(Timeline);
				TL.stop();
				AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "treadmill_servo_01_loop.mp3");
				
				overHeated = true;
				// shake it!
				var shake:ShakeMotion = gauge.get(ShakeMotion);
				shake.shakeZone = new RectangleZone(-3, 2, 3, 2);
				shake.active = true;
				foreGround.add(shake);
				foreGround.add(new SpatialAddition());
				belt.add(shake);
				belt.add(new SpatialAddition());
				// SOUND
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "machinery_heavy_shaking_01_loop.mp3", 1.6, true);
				Timeline(gaugePipe.get(Timeline)).gotoAndStop("major");
				//activate sparks
				for (var i:int = 0; i < sparks.length; i++) 
				{
					sparks[i].get(Timeline).gotoAndPlay("start");
					DisplayUtils.moveToTop(sparks[i].get(Display).displayObject);
				}
				// end game
				gameComplete = true;
				SceneUtil.delay(this, 0.7, Command.create(completeGame,"overHeat"));
				SceneUtil.lockInput(this, true);
			}
			else if(spat.rotation >= 150){
				// start shaking
				ShakeMotion(gauge.get(ShakeMotion)).active = true;
				Timeline(gaugePipe.get(Timeline)).gotoAndStop("major");
				// SOUND Looped
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "air_jet_01_loop.mp3", 0.5, true);
			}			
			else if(spat.rotation >= 110){
				Timeline(gaugePipe.get(Timeline)).gotoAndStop("moderate");
				// SOUND Looped
			}
			else if(spat.rotation >= 70){
				Timeline(gaugePipe.get(Timeline)).gotoAndStop("slight");
				// SOUND Looped
			}
			else{
				Timeline(gaugePipe.get(Timeline)).gotoAndStop("still");
			}
		}
	}
}