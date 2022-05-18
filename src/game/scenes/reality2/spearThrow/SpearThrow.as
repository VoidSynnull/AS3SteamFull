package game.scenes.reality2.spearThrow
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.input.Input;
	import game.components.motion.MotionTarget;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.data.WaveMotionData;
	import game.data.character.LookData;
	import game.scenes.poptropolis.archery.components.Arrow;
	import game.scenes.poptropolis.archery.components.Wind;
	import game.scenes.poptropolis.archery.systems.ArcherySystem;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.reality2.shared.Contest;
	import game.scenes.reality2.shared.Contestant;
	import game.scenes.reality2.spearThrow.ai.AiInput;
	import game.scenes.reality2.spearThrow.ai.SpearThrowAiSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class SpearThrow extends Contest
	{
		public var _interaction:Interaction;
		private var _interactive:MovieClip;
		private var _powerMeter:Entity;
		private var _powerBar:Entity;
		private var _windGuage:Entity;
		private var _arrowsHud:Entity;
		private var _tree:Entity;
		private var _arrow:Entity;
		private var _inArrow:Entity;
		private var _flag:Entity;
		private var _scoreboard:Entity;
		private var _exitBtn:Entity;
		private var _treeMC:MovieClip;
		
		private var buttonToolTip:ToolTip;
		private var round:int = 1;
		private const ROUNDS:int = 3;//should be 3
		private var contestant:int = 0;
		private const MAX_ARRWOS:int = 5;
		private var minValidShot:Number = 116;
		private var arrowsLeft:Number = MAX_ARRWOS;
		private var score:Number = 0;
		private var totalScore:Number = 0;
		private var gameStarted:Boolean = false;
		private var arrowReady:Boolean = false;
		private var hitSound:String = "";
		private var npcNum:int = 1;
		private var target:Entity;
		private var poof:Entity;
		private var _ai:Entity;
		private var activeContestant:Contestant;
		private var turn:Entity;
		private var turnText:TextField;
		
		private const REACTORS:Array = ["snake","toad"];
		private const TWEENS:Array = ["hippo", "croc"];
		private var tweening:String;
		
		public function SpearThrow()
		{
			super();
			practiceEnding = "Looking Good! Now get ready to throw for real!";
			contestEnding = "Nice throwing! Let's find out who won!";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/reality2/spearThrow/";
			
			super.init(container);
		}
		
		override protected function contestantDataLoaded(xml:XML):void
		{
			hitContainer.mouseEnabled = false;
			// add systems
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);           // provides additional motion on top of an entity's standard motion for movement based on math operations like sine waves.
			super.addSystem(new ArcherySystem());
			
			convertContainer(_hitContainer["fg"]);
			
			SceneUtil.setCameraPoint(this, sceneData.cameraLimits.width/2, sceneData.cameraLimits.height/2,true);
			
			setUpTurnUI();
			setupPowerBar();
			setupWindGuage();
			setupArrowsHud();
			setupScoreboard();
			setUpTargets();
			setUpAnimations();
			setUpAi();
			
			var clip:MovieClip;
			
			hud.x = sceneData.bounds.width/2;
			
			for(var i:int = 0; i < contestants.length; i++)
			{
				var contestant:Contestant = contestants[i];
				if(contestant.difficulty == Contestant.PLAYER)
				{
					contestant.id = shellApi.profileManager.active.avatarName;
					clip = setUpUi("player", i, SkinUtils.getPlayerLook(this),npcLookApplied);
					TimelineUtils.convertClip(clip["highlight"],this);
					activeContestant = contestant;
					continue;
				}
				var npc:XML = xml.child("npc")[contestant.index];
				contestant.id = DataUtils.getString(npc.attribute("id")[0]);
				var child:XML = npc.child("skin")[0];
				var look:LookData = new LookData( child);
				clip = setUpUi("c"+npcNum, i, look, npcLookApplied);
				if(clip)
				{
					TimelineUtils.convertClip(clip["highlight"],this);
				}
				npcNum++;
			}
		}
		
		private function setUpTurnUI():void
		{
			var clip:MovieClip = _hitContainer["turn"];
			clip.alpha = 0;
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			turnText = TextUtils.refreshText(clip["tf"], "Billy Serif");
			turn = EntityUtils.createSpatialEntity(this, clip);
			turn.add(new Tween());
		}
		
		private function setUpAi():void
		{
			addSystem(new SpearThrowAiSystem());
			var clip:MovieClip = new MovieClip();
			_ai = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			var vMotionData:WaveMotionData = WaveMotion(_powerBar.get(WaveMotion)).data[0];
			var input:AiInput = new AiInput(vMotionData);
			input.movements = 2;
			input.delay = .25;
			input.fire.add(shoot);
			_ai.add(input).add(new MotionTarget());
		}
		
		private function setUpAnimations():void
		{
			//snake and toad react to arrows
			var animations:Array = ["toad", "snake", "elephant", "babyElephant", "elephant2","hippo","croc"];
			
			var clip:MovieClip;
			var entity:Entity;
			for(var i:int = 0; i < animations.length; i++)
			{
				clip = _hitContainer[animations[i]];
				if(PlatformUtils.isMobileOS)
				{
					if(REACTORS.indexOf(clip.name) < 0)
					{
						_hitContainer.removeChild(clip);
						continue;
					}
				}
				convertContainer(clip);
				entity = EntityUtils.createSpatialEntity(this, clip).add(new Id(clip.name));
				TimelineUtils.convertAllClips(clip, null, this,true, 32, entity);
				if(TWEENS.indexOf(clip.name) >= 0)
				{
					entity.remove(Sleep);
					tweenAcross(clip.name);
				}
			}
			clip = _hitContainer["poof"];
			convertContainer(clip);
			poof = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertClip(clip, this, poof).get(Timeline).gotoAndStop(clip.totalFrames-1);
		}
		
		private function tweenAcross(name:String):void
		{
			if(!DataUtils.validString(tweening))
			{
				tweening = name;
				var entity:Entity = getEntityById(name);
				var spatial:Spatial = entity.get(Spatial);
				var destination:Number = spatial.x < 0? shellApi.viewportWidth * 1.25 : -shellApi.viewportWidth/4;
				spatial.scaleX = destination > 0?1:-1;
				TweenUtils.entityTo(entity, Spatial, 30, {x:destination, ease:Linear.easeNone, onComplete:Command.create(crossComplete, name)});
			}
		}
		
		private function crossComplete(crosser:String):void
		{
			tweening = null;
			var i:int = TWEENS.indexOf(crosser);
			i++;
			if(i >= TWEENS.length)
				i = 0;
				
			tweenAcross(TWEENS[i]);
		}
		
		private function setUpTargets():void
		{
			var clip:DisplayObjectContainer;
			var entity:Entity;
			for(var i:int =1; i <= ROUNDS; i++)
			{
				clip = _hitContainer["target"+i];
				if(PlatformUtils.isMobileOS)
				{
					clip = convertToBitmapSprite(clip).sprite;
				}
				entity = EntityUtils.createSpatialEntity(this, clip).add(new Id(clip.name));
				EntityUtils.visible(entity, i==1);
				if(i==1)
					target = entity;
			}
		}
		
		private function setUiIntoFocus(prefix:String):void
		{
			var clip:MovieClip;
			var highlight:MovieClip;
			var index:int;
			for(var i:int = 0; i <participants.length; i++)
			{
				var p:String = i ==0?"player":"c"+i;
				clip = hud[p+"Ui"];
				highlight = clip["highlight"];
				
				if(p == prefix)
				{
					var t:String = i == 0? "your":participants[i].id;
					t = formatId(t, true);
					
					turnText.text = "It's " + t + " turn";
					turnText.y = -turnText.textHeight/2;
					highlight.scaleX = highlight.scaleY = 1.25;
					tweenScoreIn(turn);
				}
				else
				{
					highlight.scaleX = highlight.scaleY = 1;
				}
			}
		}
		
		private function npcLookApplied(entity:Entity):void
		{
			npcNum--;
			if(npcNum <= 0 || practice)
			{
				contestantsPrepared();
				initGame();
			}
		}
		
		private function initGame():void 
		{
			setUiIntoFocus("player");
			gameStarted = true;
			npcNum =0;
			_arrow = getArrow();
			tweenFadeIn(_windGuage);
			tweenFadeIn(_powerMeter);
			tweenFadeIn(_arrowsHud);
			
			// so mobile doesn't get screwed for aiming
			(super.shellApi.inputEntity.get( Input ) as Input).inputUp.add( onHandleDown );
		}
		
		private function onHandleDown(input:Input):void {
			if(arrowReady && activeContestant.difficulty == Contestant.PLAYER){
				shoot();
			}
		}
		
		private function shoot():void 
		{
			playSound("shoot");
			if(arrowsLeft > 0){
				arrowReady = false;
				var windVariance:Number = -_powerBar.get(SpatialAddition).x;
				if(windVariance > 0){
					windVariance -= 15;
					if(windVariance < 0){
						windVariance = 0;
					}
				}else{
					windVariance += 15;
					if(windVariance > 0){
						windVariance = 0;
					}
				}
				var arrow:Arrow = _arrow.get(Arrow);
				// have to account for camera offset as well
				
				arrow.targetX = arrow.mouse.x + arrow.viewPort.x + Wind(_windGuage.get(Wind)).windSpeed;
				arrow.targetY = arrow.mouse.y + arrow.viewPort.y +10 + windVariance;
				if(arrow.targetY < 80){
					arrow.targetY = 80;
				}
				
				var spatial:Spatial = target.get(Spatial);
				var dist:Number = resolveScore();
				if(dist < minValidShot){
					arrow.finalScale = .33;
					hitSound = "hitTarget";
				}else if(arrow.targetY - 5 < spatial.y){
					arrow.finalScale = 0;
					hitSound = "arrowMiss";
				}else{
					arrow.finalScale = 0;
					hitSound = "arrowWater";
				}
				
				arrowsLeft--;
				_hitContainer["arrowsHud"]["remaining"].text = "x "+arrowsLeft;
				_arrow.get(Display).displayObject.arrow.x = -178;
				arrow.firing = true;
			}
		}
		
		private function resolveScore():Number
		{
			var spatial:Spatial = target.get(Spatial);
			var arrow:Arrow = _arrow.get(Arrow);
			var dx:Number = arrow.targetX - spatial.x; 
			var dy:Number = arrow.targetY - spatial.y - 10; 
			var dist:Number = Math.sqrt(dx*dx + dy*dy);
			
			var s:Number = Math.ceil(10-(((dist)/minValidShot)*10));
			if(s > 0){
				score = s;
				if(practice){
					totalScore += s;
				}
			}else{
				score = 0;
			}
			return dist;
		}
		
		private function getArrow():Entity 
		{
			var i:int = MAX_ARRWOS-arrowsLeft+1;
			var entity:Entity = getEntityById("arrow"+i);
			if(!entity)
			{
				entity = makeArrow(_hitContainer["arrow"+i], i);
			}
			else
			{
				// resetting arrow
				var arrow:Arrow = entity.get(Arrow);
				arrow.viewPort = activeContestant.difficulty == Contestant.PLAYER?shellApi.camera.viewport : new Rectangle();
				arrow.arrowReady.addOnce(onReady);
				arrow.fired = false;
				var display:Display = entity.get(Display);
				display.displayObject.arrow.gotoAndStop(1);
				display.displayObject.arrow.x = 0;
				arrowReady = true;
			}
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = shellApi.camera.viewport.right + 20;
			spatial.y = shellApi.camera.viewport.bottom - 12;
			spatial.scaleY = spatial.scaleX = 1;
			spatial.rotation = -135;
			
			return entity;
		}
		
		private function setUpArrowToFire():void
		{
			EntityUtils.visible(_arrow);
			var arrow:Arrow = _arrow.get(Arrow);
			if(activeContestant.difficulty == Contestant.PLAYER)
			{
				arrow.mouse = Input(super.shellApi.inputEntity.get(Input)).target;
			}
			else
			{
				var spatial:Spatial = target.get(Spatial);
				MotionTarget(_ai.get(MotionTarget)).targetSpatial = target.get(Spatial);
				var ai:AiInput = _ai.get(AiInput);
				ai.accuracy = activeContestant.difficulty;
				ai.aimRadius = spatial.width/2;
				arrow.mouse = ai.target;
				ai.aiming = true;
			}
		}
		
		private function makeArrow(clip:MovieClip, count:int):Entity 
		{
			//Get MovieClip from SWF
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			clip.arrow.gotoAndStop(1);
			
			//Create and configure entity
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			var arrow:Arrow = new Arrow(Input(super.shellApi.inputEntity.get(Input)).target, shellApi.camera.viewport);
			arrow.arrowReady.addOnce(onReady);
			entity.add(arrow).add(new Id("arrow"+count));
			
			arrowReady = true;
			return entity;
		}
		
		private function onReady():void {
			playHitSound();
			var participant:Contestant = participants[npcNum];
			participant.score += score;
			var prefix:String = npcNum == 0? "player":"c"+npcNum;
			var clip:MovieClip = hud[prefix+"Ui"];
			TextField(clip["score"]).text = ""+participant.score;
			determinePlaces();
			
			var arrow:Arrow = _arrow.get(Arrow);
			var spatial:Spatial = poof.get(Spatial);
			
			if(hitSound == "hitTarget")
			{
				spatial.x = arrow.targetX;
				spatial.y = arrow.targetY;
				Timeline(poof.get(Timeline)).play();
			}
			
			for(var i:int = 0; i < REACTORS.length; i++)
			{
				var entity:Entity = getEntityById(REACTORS[i]);
				spatial = entity.get(Spatial);
				var distance:Number = Point.distance(new Point(spatial.x, spatial.y), new Point(arrow.targetX, arrow.targetY));
				if(distance <spatial.width/2)
				{
					Timeline(entity.get(Timeline)).gotoAndPlay("hit");
				}
			}
			
			if(arrowsLeft > 0)
			{
				_arrow = getArrow();
				setUpArrowToFire();
			}
			else
			{
				///////GAME OVER :: Send to scoreboard or instructions screen
				//round ended move on to next person or end game
				if(practice)
				{
					gameOver();
				}
				else
				{
					totalScore = 0;
					npcNum++;
					if(npcNum >= participants.length)
					{
						round++;
						
						if(round > ROUNDS)
						{
							gameOver();
							return;
						}
						var tf:TextField = _hitContainer["windGuage"]["roundNumber"];
						tf.text = ""+round;
						
						EntityUtils.visible(target, false);
						target = getEntityById("target"+round);
						EntityUtils.visible(target);
						minValidShot = Spatial(target.get(Spatial)).width/2;
						npcNum = 0;
					}
					
					while(arrowsLeft < MAX_ARRWOS)
					{
						arrowsLeft++;
						EntityUtils.visible(getArrow(), false);
					}
					_hitContainer["arrowsHud"]["remaining"].text = "x "+arrowsLeft;
					prefix = npcNum == 0? "player":"c"+npcNum;
					setUiIntoFocus(prefix);
					activeContestant = participants[npcNum];
					_arrow = getArrow();
					setUpArrowToFire();
				}
			}
			showScore();
		}
		
		private function determinePlaces():void
		{
			var places:Array = [];
			var contestant:Contestant;
			// want to get set of contestants that can be rearranged
			// by place with out messing up order
			for(var i:int = 0; i < participants.length; i++)
			{
				places.push(participants[i]);
			}
			//order contestants by score
			places.sortOn("score", Array.NUMERIC);
			for(i = 0; i < places.length; i++)
			{
				contestant = places[i];
				contestant.place = places.length-i;
			}
			var prefix:String;
			var tf:TextField;
			//update ui to show place
			for(i = 0; i < participants.length; i++)
			{
				contestant = participants[i];
				prefix = i==0? "player":"c"+i;
				tf = hud[prefix+"Ui"]["place"];
				tf.text = ""+contestant.place;
			}
		}
		
		override protected function gameOver(...args):void
		{
			tweenFadeOut(_windGuage);
			tweenFadeOut(_powerMeter);
			tweenFadeOut(_arrowsHud);
			trace("totalScore = "+totalScore);
			SceneUtil.delay(this, 2,super.gameOver);
		}
		
		private function dataLoaded( pop:Poptropolis ):void {
			pop.reportScore( Matches.ARCHERY, totalScore );
		}
		
		private function showScore():void
		{
			if(score != 0){
				//scoreboard.get(Display).alpha = 0;
				_scoreboard.get(Display).displayObject.points.text = score;
				tweenScoreIn(_scoreboard);
				if(score > 0 && score <= 3){
					playSound("1-3");
				}else if(score > 3 && score <= 6){
					playSound("4-6");
				}else if(score > 6 && score <= 9){
					playSound("7-9");
				}else if(score == 10){
					playSound("perfect10");
				}
			}
		}
		
		private function tweenScoreIn(entity:Entity):void{
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), .25, { alpha:1, ease:Sine.easeInOut,	onComplete:tweenScoreOut, onCompleteParams:[entity] });
		}
		
		private function tweenScoreOut(entity:Entity):void{
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), 1, { alpha:0, delay:3, ease:Sine.easeInOut });
		}
		
		private function tweenFadeIn(entity:Entity):void {
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), 0.5, { alpha:1, ease:Sine.easeInOut });
		}
		
		private function tweenFadeOut(entity:Entity):void {
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Display), 0.5, { alpha:0, ease:Sine.easeInOut });
		}
		
		private function setupPowerBar():void
		{
			//add powerMeter
			var clip:MovieClip = _hitContainer["powerMeter"];
			convertContainer(clip);
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_powerMeter = EntityUtils.createSpatialEntity(this, clip);
			_powerMeter.add(new Tween());
			_powerMeter.get(Display).alpha = 0;
			
			//add powerMeter bar
			var vClip:MovieClip = clip["bar"];
			_powerBar = EntityUtils.createSpatialEntity(this, vClip);
			
			// add wave motion component
			var vWaveMotion:WaveMotion = new WaveMotion();
			var vWaveMotionData:WaveMotionData = new WaveMotionData();
			vWaveMotionData.property = "x";
			vWaveMotionData.magnitude = 120;
			vWaveMotionData.rate = 2;
			vWaveMotionData.useTime = true;
			vWaveMotionData.radians = 0;
			vWaveMotionData.type = "sin"; // default is "sin"
			vWaveMotion.data.push(vWaveMotionData);
			_powerBar.add(vWaveMotion);
			
			// spatial addition causes the wave motion to be added on top of the spacial x,y values
			var vSpatialAddition:SpatialAddition = new SpatialAddition(); 
			_powerBar.add(vSpatialAddition);
			
			//powerBar.get(Display).alpha = 0;
			//hits.powerMeter.alpha = 0;
		}
		
		private function setupScoreboard():void
		{
			var clip:MovieClip = _hitContainer["scoreboard"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			TextUtils.refreshText(clip["points"], "Billy Serif");
			_scoreboard = EntityUtils.createSpatialEntity(this, clip);
			_scoreboard.add(new Tween());
			_scoreboard.get(Display).alpha = 0;
		}
		
		private function setupArrowsHud():void
		{
			var clip:MovieClip = _hitContainer["arrowsHud"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			var tf:TextField = TextUtils.refreshText(clip["remaining"],"Billy Serif");
			tf.text = "x "+arrowsLeft;
			_arrowsHud = EntityUtils.createSpatialEntity(this, clip);
			_arrowsHud.add(new Tween());
			_arrowsHud.get(Display).alpha = 0;
		}
		
		private function setupWindGuage():void
		{
			var clip:MovieClip = _hitContainer["windGuage"];
			//convertContainer(clip);
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_windGuage = EntityUtils.createSpatialEntity(this, clip);
			_windGuage.add(new Tween());
			
			_windGuage.add(new Wind());
			var tf:TextField = TextUtils.refreshText(clip["windSpeed"],"Billy Serif");
			tf.text = ""+Math.abs(Math.ceil(Wind(_windGuage.get(Wind)).windSpeed/5));
			_windGuage.get(Display).alpha = 0;
			TextUtils.refreshText(clip["roundNumber"],"Billy Serif");
		}
		
		private function playHitSound():void
		{
			playSound(hitSound);
		}
		
		private function playSound(sound:String):void {
			switch(sound){
				case "mainThemeFull":
					AudioUtils.play(this, SoundManager.MUSIC_PATH + "Poptropolis_Main_Theme_Full.mp3", 1, true);
					break;
				case "shoot":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "snap_band_01.mp3");
					break;
				case "arrowWater":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_splash_06.mp3");
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "miss_points_01.mp3");
					break;
				case "hitTarget":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "arrow_hit_target_board_01.mp3");
					break;
				case "arrowMiss":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "arrow_miss_01.mp3");
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "miss_points_01.mp3");
					break;
				case "perfect10":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03d.mp3");
					break;
				case "7-9":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03c.mp3");
					break;
				case "4-6":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03b.mp3");
					break;
				case "1-3":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_03a.mp3");
					break;
				case "missPoint":
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "miss_points_01.mp3");
					break;
			}
		}
	}
}