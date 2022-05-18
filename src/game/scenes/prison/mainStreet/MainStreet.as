package game.scenes.prison.mainStreet
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Skin;
	import game.components.motion.FollowTarget;
	import game.components.motion.Proximity;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Sing;
	import game.data.character.LookData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.ItemGroup;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.hill.Hill;
	import game.systems.motion.ProximitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MainStreet extends PrisonScene
	{
		private var lady:Entity;
		private var blades:Entity;
		private var muscles:Entity;
		private var tex:Entity;
		private var bandit:Entity;
		
		private var emitter:Emitter2D;
		private var emitterEntity:Entity;
		private var seagull:Entity;
		
		private var blade1:Entity;
		private var blade2:Entity;
		
		private var stopBlades:Boolean = false;
		
		public function MainStreet()
		{
			this.mergeFiles = true;
			super();
		}
		
		override public function destroy():void
		{
			lady = null;
			blades = null;
			muscles = null;
			tex = null;
			bandit = null;
			emitter = null;
			emitterEntity = null;
			seagull = null;
			blade1 = null;
			blade2 = null;
			
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/mainStreet/";
			
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
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			lady = this.getEntityById("lady");
			blades = this.getEntityById("blades");
			muscles = this.getEntityById("muscles");
			tex = this.getEntityById("tex");
			bandit = this.getEntityById("bandit");
			tex.get(Spatial).x = -100;
			bandit.get(Spatial).x = -100;
			
			EntityUtils.getDisplay(lady).moveToBack();
			
			Sleep(bandit.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(bandit.get(Sleep)).sleeping = false;
			
			CharUtils.moveToTarget(bandit, -110, 1690, false);
			
			var clip:MovieClip = _hitContainer["proximityEntity"];
			clip.visible = false;
			
			setupBlades();
			if(this.shellApi.checkHasItem(_events.MEDAL_PRISON)) {
				Dialog(blades.get(Dialog)).setCurrentById("after_medal");
				Dialog(lady.get(Dialog)).setCurrentById("after_medal");
				Dialog(muscles.get(Dialog)).setCurrentById("after_medal");
				this.removeEntity(tex);
			} else if(this.shellApi.checkEvent(_events.BANDIT_CAPTURED)) {
				SceneUtil.lockInput(this, true);
				tex.get(Spatial).x = 3850;
				tex.get(Spatial).y = 1660;
				CharUtils.setDirection(tex, false);
				CharUtils.setDirection(player, true);
				Dialog(player.get(Dialog)).sayById("well");
				Dialog(blades.get(Dialog)).setCurrentById("after_medal");
				Dialog(lady.get(Dialog)).setCurrentById("after_medal");
				Dialog(muscles.get(Dialog)).setCurrentById("after_medal");
			} else if(!this.shellApi.checkEvent(_events.SAW_BANDIT)) {
				//setupDialog();
				setupProximityEntity();
				startDelay(1);
				resetIsland();
			} else {
				setAfterTheif();
			}
			
			setupBandit();
			setupFans();
			setupBird();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(2130, 1350),"minibillboard/minibillboardMedLegs.swf");	

			super.loaded();
		}
		
		private function resetIsland():void
		{
			shellApi.setUserField(_events.GUM_FIELD, "0", shellApi.island);
			shellApi.setUserField(_events.DAYS_IN_PRISON_FIELD, "0", shellApi.island);
			shellApi.setUserField(_events.SUNFLOWER_FIELD, "0,0", shellApi.island);
			shellApi.setUserField(_events.VENT_CHISELS, null, shellApi.island);
			shellApi.setUserField(_events.VENTS_FIELD_METAL, null, shellApi.island);
			shellApi.setUserField(_events.VENTS_FIELD_MESS, null, shellApi.island);
			shellApi.setUserField(_events.LICENSE_PLATES_MADE_FIELD, null, shellApi.island);
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		private function startDelay(num:Number):void {
			var rand:Number = Math.random() * 4;
			if(!stopBlades){
				if(num == 1){
					SceneUtil.addTimedEvent(this, new TimedEvent(rand, 1, rollLeft, true));
				} else {
					SceneUtil.addTimedEvent(this, new TimedEvent(rand, 1, rollRight, true));
				}
			}
		}
		
		private function rollRight():void {
			CharUtils.setDirection(blades, true);
			CharUtils.setAnim(blades, Sing);
			TweenUtils.globalTo(this,blades.get(Spatial),2,{x:1700, delay:0, ease:Sine.easeInOut, onComplete:startDelay, onCompleteParams:[1]},"tester");
		}
		
		private function rollLeft():void {
			CharUtils.setDirection(blades, false);
			CharUtils.setAnim(blades, Sing);
			TweenUtils.globalTo(this,blades.get(Spatial),2,{x:1500, delay:0, ease:Sine.easeInOut, onComplete:startDelay, onCompleteParams:[2]},"tester");
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "blades_hit" ) {
				var targX:Number = blades.get(Spatial).x - 200;
				CharUtils.moveToTarget(player, targX, 1690, false, sayHeroLine);
			} else if( event == "stop" ) {
				tex.get(Spatial).x = -100;
				var bladesThreshold:Threshold = new Threshold( "x", ">" );
				bladesThreshold.threshold = 1527;
				bladesThreshold.entered.add( bladesFall );
				bandit.add( bladesThreshold );
				if( !super.systemManager.getSystem( ThresholdSystem )) {
					super.addSystem( new ThresholdSystem());
				}
				super.shellApi.camera.target = bandit.get(Spatial);
				CharUtils.moveToTarget(bandit, 4000, 1690, false, finishBanditRun);
			} else if( event == "run_off" ) {
				super.shellApi.camera.target = player.get(Spatial);
				SceneUtil.lockInput(this, false);
			} else if( event == "get_medallion" ) {
				showEndingPopup();
			}
		}
		
		private function showEndingPopup():void
		{
			this.shellApi.getItem(_events.MEDAL_PRISON);
			SceneUtil.lockInput(this, false);
			//if (completionsUpdated) {
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
			islandEndPopup.popupRemoved.addOnce(endingPopupClosed);
			shellApi.completedIsland("", null);
			//completeIsland();
			//} else {
			//	endingPopupWaiting = true;
			//}
		}
		
		private function endingPopupClosed():void {
			SceneUtil.lockInput(this, false);
			Dialog(tex.get(Dialog)).setCurrentById("great_job");
		}
		
		private function setupProximityEntity():void
		{
			var clip:MovieClip = _hitContainer["proximityEntity"];
			var proximityEntity:Entity = EntityUtils.createSpatialEntity(this, clip);
			proximityEntity.get(Display).alpha = 0;
			
			this.addSystem(new ProximitySystem());
			
			var proximity:Proximity = new Proximity(500, this.player.get(Spatial));
			proximityEntity.add(proximity);
			proximity.entered.add(checkProximity);
		}
		
		private function checkProximity(entity:Entity=null):void {
			if(player.get(Spatial).y > 1650) {
				entity.get(Proximity).entered.removeAll();
				seeBandit();
			}
		}
		
		private function sayHeroLine(entity:Entity):void {
			CharUtils.setDirection(player, true);
			Dialog(player.get(Dialog)).sayById("stop");
		}
		
		private function loadHill(entity:Entity=null):void {
			this.shellApi.loadScene(Hill, 20, 2965, "right");
		}
		
		private function bladesFall():void {
			super.shellApi.camera.target = blades.get(Spatial);
			Dialog(blades.get(Dialog)).sayById("oof");
			bladesHit();
		}
		
		public function seeBandit(entity:Entity=null):void {
			stopBlades = true;
			SceneUtil.lockInput(this, true);
			super.shellApi.camera.target = lady.get(Spatial);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, showBandit, true));
			
			emitter = new Emitter2D();
			emitter.counter = new Random(0, 2);
			emitter.addInitializer( new ExternalImage("assets/scenes/prison/mainStreet/money.swf") );
			emitter.addInitializer(new Position(new RectangleZone(0, 0, 0, 0)));
			emitter.addInitializer( new Velocity( new PointZone( new Point(-60, 0) ) ) );
			emitter.addInitializer(new Lifetime(3));
			emitter.addInitializer(new ScaleImageInit(1, 1));
			emitter.addInitializer(new RotateVelocity(0, 5));
			emitter.addAction(new Rotate());
			emitter.addAction(new RandomDrift(100, 20));
			emitter.addAction(new Move());
			emitter.addAction(new Age());
			emitter.addAction(new Accelerate(0, 260));
			
			emitterEntity = EmitterCreator.create(this, _hitContainer, emitter);
			var spatial:Spatial = emitterEntity.get(Spatial);
			spatial.x = 400;
			spatial.y = 1600;
			
			var followTarget:FollowTarget = new FollowTarget( bandit.get( Spatial ));
			followTarget.offset = new Point( 10, 0 );
			followTarget.properties = new <String>["x", "y"];
			emitterEntity.add( followTarget );
		}
		
		private function showBandit():void {
			tex.get(Display).alpha = 0;
			tex.get(Spatial).x = 0;
			DialogData(Dialog(tex.get(Dialog)).allDialog["stop"]).forceOnScreen = true;
			Dialog(tex.get(Dialog)).sayById("stop");
		}
		
		private function finishBanditRun(entity:Entity):void {
			this.removeEntity(bandit);
			this.shellApi.completeEvent(_events.SAW_BANDIT);
			emitter.stop();
			this.removeEntity(emitterEntity);
		}
		
		//hit blades guy
		private function bladesHit():void {
			blades.add(new Tween());
			blades.add(new SpatialOffset());
			
			blades.get(Tween).to(blades.get(Spatial), 1, { delay:0, x:1837, y:1660, rotation:"720", ease:Linear.easeNone });
			blades.get(Tween).to(blades.get(SpatialOffset), .5, { delay:0, y:-200, ease:Linear.easeNone, onComplete:endBounce });
			CharUtils.setAnim(blades, game.data.animation.entity.character.Hurt);
		}
		
		private function endBounce():void {
			blades.get(Tween).to(blades.get(SpatialOffset), 1, { y:0, ease:Bounce.easeOut, onComplete:finishBladesHit });
		}
		
		private function finishBladesHit():void {
			setAfterTheif();
		}
		
		private function dazed(entity:Entity):void {
			blades.get(Spatial).rotation = 0;
			CharUtils.setAnim(blades, game.data.animation.entity.character.Dizzy);
			Sleep(blades.get(Sleep)).ignoreOffscreenSleep = true;
			blades.get(Timeline).gotoAndPlay(10);
		}
		//end hit blades guy
		
		private function setAfterTheif():void {
			CharUtils.stateDrivenOff(blades);
			dazed(blades);
			Dialog(blades.get(Dialog)).faceSpeaker = false;
			Dialog(blades.get(Dialog)).setCurrentById("after_theif");
			Dialog(lady.get(Dialog)).setCurrentById("after_theif");
			Dialog(muscles.get(Dialog)).setCurrentById("after_theif");	
			SkinUtils.setSkinPart(lady, SkinUtils.MOUTH, "distressedMom");
			SkinUtils.setSkinPart(muscles, SkinUtils.MOUTH, "rat");
			if(getEntityById("blades")) 
			{
				blade1.get(Spatial).rotation = 30;
				blade2.get(Spatial).rotation = 30;
				blade1.get(Spatial).y = 13;
				blade2.get(Spatial).y = 13;
			}
		}
		
		private function setupBird():void {
			var clip:MovieClip = _hitContainer["seagull"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			seagull = EntityUtils.createMovingTimelineEntity(this, clip, null, true);
			seagull.add(new Id("seagull"));
			EntityUtils.getDisplay(seagull).moveToFront();
			Timeline(seagull.get(Timeline)).handleLabel("squak",birdSound,false);
			Timeline(seagull.get(Timeline)).handleLabel("endIdle",testIdle,false);
		}
		
		private function testIdle(...p):void {
			if(Math.random() < .33){
				Timeline(seagull.get(Timeline)).gotoAndPlay("squak");
			}
		}
		
		private function birdSound(...p):void
		{
			AudioUtils.playSoundFromEntity(getEntityById("seagull"), SoundManager.EFFECTS_PATH+"seagull_squawk_01.mp3");
		}
		
		private function setupBandit():void {
			if(bandit){
				var foot:Entity = Skin( bandit.get( Skin )).getSkinPartEntity( "foot1" );
				var footDisplay:Display = foot.get( Display );
				var boot1:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["boot1"], footDisplay.displayObject);
				boot1.get(Spatial).scale = 3;
				boot1.get(Spatial).x = 0;
				boot1.get(Spatial).y = 0;
				
				var foot2:Entity = Skin( bandit.get( Skin )).getSkinPartEntity( "foot2" );
				var footDisplay2:Display = foot2.get( Display );
				var boot2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["boot2"], footDisplay2.displayObject);
				boot2.get(Spatial).scale = 3;
				boot2.get(Spatial).x = 0;
				boot2.get(Spatial).y = 0;
				
				var lookData:LookData = new LookData();
				lookData.applyAspect( SkinUtils.getLookAspect(player, SkinUtils.SKIN_COLOR) );
				SkinUtils.applyLook( bandit, lookData, false );
			}
			EntityUtils.getDisplay(bandit).moveToFront();
		}
		
		private function setupBlades():void {
			if(this.getEntityById("blades")){
				var foot:Entity = Skin( blades.get( Skin )).getSkinPartEntity( "foot1" );
				var footDisplay:Display = foot.get( Display );
				blade1 = EntityUtils.createSpatialEntity(this, _hitContainer["blade1"], footDisplay.displayObject);
				blade1.get(Spatial).scale = 3;
				blade1.get(Spatial).x = 0;
				blade1.get(Spatial).y = 0;
				
				var foot2:Entity = Skin( blades.get( Skin )).getSkinPartEntity( "foot2" );
				var footDisplay2:Display = foot2.get( Display );
				blade2 = EntityUtils.createSpatialEntity(this, _hitContainer["blade2"], footDisplay2.displayObject);
				blade2.get(Spatial).scale = 3;
				blade2.get(Spatial).x = 0;
				blade2.get(Spatial).y = 0;
			}
		}
		
		private function setupFans():void {
			var fan1:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["fan1"]);
			var fan2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["fan2"]);
			fan1.get(Display).visible = false;
			fan2.get(Display).visible = false;
			var audio:Audio = new Audio();
			audio.play(SoundManager.AMBIENT_PATH + "air_ducts_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			
			var audio2:Audio = new Audio();
			audio2.play(SoundManager.AMBIENT_PATH + "air_ducts_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			
			fan1.add(audio);
			fan1.add(new AudioRange(500, 0, 1, Quad.easeIn));
			fan1.add(new Id("soundSource"));
			
			fan2.add(audio2);
			fan2.add(new AudioRange(500, 0, 1, Quad.easeIn));
			fan2.add(new Id("soundSource2"));
		}
	}
}