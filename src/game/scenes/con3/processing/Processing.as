package game.scenes.con3.processing
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.data.display.SharedBitmap;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.entity.Dialog;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.PlacePitcher;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.specialAbility.islands.poptropicon.PowerGlove;
	import game.scene.template.AudioGroup;
	import game.scenes.con3.Con3Scene;
	import game.scenes.con3.shared.BarrierGroup;
	import game.scenes.con3.shared.ElectricPulseGroup;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Processing extends Con3Scene
	{
		private var _sceneObjectCreator:SceneObjectCreator;
		private var goldface:Entity;
		private var hench0:Entity;
		private var hench1:Entity;
		private var pinata:Entity;
		private var wizard:Entity;
		private var machine:Entity;
		private var powerSwitch:Entity;
		private var belt0:Entity;
		private var belt1:Entity;
		private var wires:Entity;
		private var sparks:Entity;
		
		private const IDLE:String					= "idle";
		private const TRIGGER:String			 	= "trigger";
		
		private const MACHINE_SHAKE:String = SoundManager.EFFECTS_PATH + "shake_machine_01.mp3";
		private const MACHINE_BREAK:String = SoundManager.EFFECTS_PATH + "power_on_06.mp3";
		private const MACHINE_CLOSE:String = SoundManager.EFFECTS_PATH + "door_hatch_01.mp3";
		private const BELT_START:String = SoundManager.EFFECTS_PATH + "small_electric_machine_01.mp3";
		private const DROP_IN_BIN:String = SoundManager.EFFECTS_PATH + "metal_junk_impact_01.mp3";
		private const SHOCK_BOT:String = SoundManager.EFFECTS_PATH + "electric_field_02_loop.mp3";
		private const ZAP:String = SoundManager.EFFECTS_PATH + "electrical_impact_02.mp3";
		private const SPARK:String = SoundManager.EFFECTS_PATH + "electric_zap_07.mp3";
		private const EXPLODE:String = SoundManager.EFFECTS_PATH + "small_explosion_04.mp3";
		private const CHARGE:String = SoundManager.EFFECTS_PATH + "power_on_07c.mp3";
		private const POWER_DOWN:String = SoundManager.EFFECTS_PATH +"power_down_06.mp3";
		
		private var _sparkSequence:BitmapSequence;
		private var _beltSequence:BitmapSequence;
		private var _wireSequence:BitmapSequence;
		private var _machineSequence:BitmapSequence;
		
		public function Processing()
		{
			super();
		}
		
		override protected function addBaseSystems():void
		{
			if( PlatformUtils.isDesktop )
			{
				addSystem(new ElectrifySystem(),SystemPriorities.update);
			}
			super.addBaseSystems();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/processing/";
			//showHits = true
			super.init(container);
		}
		
		override public function destroy():void
		{
			if( _sparkSequence )
			{
				_sparkSequence.destroy();
				_sparkSequence= null;
			}
			if( _beltSequence )
			{
				_beltSequence.destroy();
				_beltSequence= null;
			}
			if( _wireSequence )
			{
				_wireSequence.destroy();
				_wireSequence= null;
			}
			if( _machineSequence )
			{
				_machineSequence.destroy();
				_machineSequence= null;
			}
			super.destroy();
		}
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function setUpScene():void
		{
			super.setUpScene();
			addSystem(new ShakeMotionSystem());
			addSystem(new HazardHitSystem());
			
			shellApi.eventTriggered.add(handleEventTrigger);
			
			goldface = this.getEntityById("goldFace");
			
			setupPushBoxes();
			
			var barrierGroup:BarrierGroup = this.addChildGroup( new BarrierGroup()) as BarrierGroup;
			barrierGroup.createBarriers( this, _hitContainer );
			
			setupMachine();
			
			var validHit:ValidHit = new ValidHit("pushwall","belt");
			validHit.inverse = true;
			player.add(validHit);
			
			// spot gold face
			if(!shellApi.checkEvent(_events.GOLD_FACE_SPOTTED)){
				var cagezone:Entity = getEntityById("cageZone");
				var zone:Zone = cagezone.get(Zone);
				zone.entered.add(seeGoldface);
			}
		}
		
		private function seeGoldface(z:String, i:String):void
		{
			if(i=="player"){
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				actions.addAction(new PanAction(goldface));
				actions.addAction(new TalkAction(goldface,"help"));
				actions.addAction(new WaitAction(0.5));
				actions.addAction(new PanAction(player));
				actions.addAction(new CallFunctionAction(Command.create(shellApi.completeEvent,_events.GOLD_FACE_SPOTTED)));
				actions.execute();
				removeEntity(getEntityById(z),true);
			}
		}
		
		private function handleEventTrigger(event:String, ...junk):void
		{
			/*if(event == _events.USE_GAUNTLETS){
			approachGlove();
			}
			else */if(event == _events.USE_ELECTRON){
				useElectronBlast();
			}
			else if(event == _events.GOT_SODA){
				giveSoda();
			}
		}
		
		private function giveSoda():void
		{
			shellApi.completeEvent(_events.GOT_SODA + "1");
			shellApi.completeEvent(_events.HAS_SODA + "1");
			if(shellApi.checkHasItem(_events.SODA)){
				shellApi.showItem(_events.SODA, null);
			}else{
				shellApi.getItem(_events.SODA, null, true);
			}
			SkinUtils.setSkinPart(wizard, SkinUtils.ITEM, "empty", true);
		}
		
		private function useElectronBlast(...p):void
		{
			// free wizard if in range of blue thing
			var dist:Number = GeomUtils.distPoint(EntityUtils.getPosition(player), EntityUtils.getPosition(powerSwitch));
			if(dist <= 200){
				rescueWizard();
			}
		}
		
		private function rescueWizard():void
		{
			// wait till energy blast finshed, open machine, wizard escapes, talk about soda, get soda
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			AudioUtils.playSoundFromEntity(machine, POWER_DOWN, 500, 1.1, 1.1);
			actions.addAction(new TimelineAction(machine,"start","closed"));
			actions.addAction(new TimelineAction(machine,"open"));
			if(!shellApi.checkEvent(_events.WIZARD_FREED)){
				CharUtils.setAnim(wizard, Stand, false, 20, 0, true);
				var can:Entity = SkinUtils.getSkinPartEntity(wizard, SkinUtils.ITEM);
				removeElectrify(can);
				actions.addAction(new PanAction(wizard));
				actions.addAction(new MoveAction(wizard,new Point(1010,750),new Point(35,100)));
				actions.addAction(new CallFunctionAction(moveUp));
				actions.addAction(new MoveAction(wizard,new Point(1121,900),new Point(35,100)));
				var pPos:Point = EntityUtils.getPosition(player);
				pPos.x += 170;
				actions.addAction(new MoveAction(wizard,pPos,new Point(30,50),0));
				actions.addAction(new TalkAction(wizard,"thanks"));
				actions.addAction(new TalkAction(wizard,"here"));	
				actions.addAction(new CallFunctionAction(takeSoda));
				actions.addAction(new PanAction(player));
				actions.addAction(new MoveAction(wizard,new Point(1755,650),new Point(50,50)));
				actions.addAction(new CallFunctionAction(Command.create(ToolTipCreator.removeFromEntity,wizard)));
				actions.addAction(new CallFunctionAction(Command.create(removeEntity,wizard)));
				actions.addAction(new CallFunctionAction(Command.create(shellApi.completeEvent,_events.WIZARD_FREED)));
				actions.addAction(new PanAction(player));
			}
			SceneUtil.addTimedEvent(this, new TimedEvent(0.6, 1, actions.execute));
		}
		
		private function takeSoda():void
		{
			if(wizard){
				SkinUtils.setSkinPart(wizard,SkinUtils.ITEM,"empty");
			}
		}
		
		private function moveUp(...p):void
		{
			DisplayUtils.moveToTop( EntityUtils.getDisplayObject(wizard));
		}
		
		private function setupMachine():void
		{
			// chars
			pinata = getEntityById("pinata");
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(pinata));
			ToolTipCreator.removeFromEntity(pinata);
			pinata.remove(Interaction);
			pinata.remove(SceneInteraction);
			
			wizard = getEntityById("wizard");
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(wizard));
			ToolTipCreator.removeFromEntity(wizard);
			wizard.remove(Interaction);
			wizard.remove(SceneInteraction);
			
			hench0 = getEntityById("hench0");
			ToolTipCreator.removeFromEntity(hench0);
			hench0.remove(Interaction);
			hench0.remove(SceneInteraction);
			
			hench1 = getEntityById("hench1");
			ToolTipCreator.removeFromEntity(hench1);
			hench1.remove(Interaction);
			hench1.remove(SceneInteraction);
			MovieClip(hench1.get(Display).displayObject).mouseChildren = false;
			MovieClip(hench1.get(Display).displayObject).mouseEnabled = false;
			
			var clip:MovieClip = _hitContainer["machine0"];
			var bitmap:SharedBitmap = BitmapUtils.createBitmap(clip["mach"], PerformanceUtils.defaultBitmapQuality + 0.3);
			DisplayUtils.swap(bitmap, clip["mach"]);
			_machineSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
			machine = makeEntity( clip, false, _machineSequence );
			
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-2, -1, 2, 1));
			shake.active = false;
			machine.add(shake);
			machine.add(new SpatialAddition());
			
			clip = _hitContainer["belt0"];
			_beltSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
			belt0 = makeEntity( clip, false, _beltSequence );
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(belt0));
			
			clip = _hitContainer["belt1"];
			belt1 = makeEntity( clip, false, _beltSequence );
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(belt1));
			
			setupSparkPanel();
			
			clip = _hitContainer["crate"];
			makeEntity( clip, false, null );
		///	var spr:Sprite = BitmapUtils.createBitmapSprite(clip, PerformanceUtils.defaultBitmapQuality);
		///	var spr:BitmapWrapper = 
//			wrapper = super.convertToBitmapSprite( clip, null, true, PerformanceUtils.defaultBitmapQuality );
//			EntityUtils.createSpatialEntity( this, wrapper.sprite ).add(new Id("crate"));
			
			var electricPulseGroup:ElectricPulseGroup = this.addChildGroup( new ElectricPulseGroup()) as ElectricPulseGroup;
			electricPulseGroup.createPanels( _hitContainer[ "panel0" ], this, _hitContainer, useElectronBlast, "machine", null, null );
			powerSwitch = getEntityById("panel0");
			
			if(!shellApi.checkEvent(_events.MACHINE_BROKEN)){
				//transform first guy, break on wizard
				runTransformSequence();
			}
			else{
				if(!shellApi.checkEvent(_events.WIZARD_FREED)){
					setMachineBroken();
				}else{
					// wizard rescued
					setMachineEmpty();
				}
			}
		}
		
		private function setupSparkPanel():void
		{
			var clip:MovieClip = _hitContainer["wires"];
			_wireSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
			
			wires = makeEntity(clip,false, _wireSequence);
		//	wires.add(new Id("wires"));
			InteractionCreator.addToEntity( wires, [InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity( wires );
			// charge glove on sparky wires	
			var sceneInteraction:SceneInteraction = new SceneInteraction();	
			sceneInteraction.offsetY = 100;
			sceneInteraction.minTargetDelta = new Point(30,120);
			sceneInteraction.reached.add(sparkReached);
			wires.add(sceneInteraction);
			
			clip = _hitContainer["sparks"];
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			_sparkSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3); 
			sparks = makeEntity(clip,false, _sparkSequence);
//			sparks.add(new Id("sparks"));
			
			if(shellApi.checkEvent(_events.MACHINE_BROKEN)){
				Timeline(sparks.get(Timeline)).play();
				Timeline(sparks.get(Timeline)).handleLabel("zap",sparkSound,false);
				Timeline(sparks.get(Timeline)).handleLabel("zap2",sparkSound,false);
				Timeline(wires.get(Timeline)).gotoAndStop("broke");
			}
		}
		
		private function sparkSound(...p):void
		{
			AudioUtils.playSoundFromEntity(sparks, SPARK, 600, 0, 0.85);
		}
		
		private function setMachineBroken():void
		{
			// wizard stuck inside
			EntityUtils.position(wizard,730,745);
			zapSoda();
			Timeline(machine.get(Timeline)).gotoAndStop("start");
			//addMachineSparks();
			ToolTipCreator.removeFromEntity(wizard);
			removeEntity(hench0);
			Spatial(hench1.get(Spatial)).x += 200;
			CharUtils.setAnim(hench1, game.data.animation.entity.character.Sleep);
			SkinUtils.setSkinPart(hench1, SkinUtils.EYES, "hypnotized");
			ToolTipCreator.removeFromEntity(wizard);
			removeEntity(pinata);
		}
		
		private function setMachineEmpty():void
		{
			// post wizard rescue state			
			ToolTipCreator.removeFromEntity(pinata);
			removeEntity(pinata);	
			ToolTipCreator.removeFromEntity(wizard);
			removeEntity(wizard);
			ToolTipCreator.removeFromEntity(hench0);
			removeEntity(hench0);
			Spatial(hench1.get(Spatial)).x += 200;
			CharUtils.setAnim(hench1, game.data.animation.entity.character.Sleep);
			SkinUtils.setSkinPart(hench1, SkinUtils.EYES, "hypnotized");
			Timeline(machine.get(Timeline)).gotoAndStop("start");
		}
		
		private function runTransformSequence():void
		{
			var action:ActionChain = new ActionChain(this);
			action.lockInput = true;
			action.addAction(new PanAction(pinata));
			action.addAction(new TalkAction(pinata,"tyrants"));
			action.addAction(new TalkAction(hench1,"silence"));
			// hench press button
			action.addAction(new AnimationAction(hench0, PointItem, "pointing"));
			action.addAction(new CallFunctionAction(Command.create(shellApi.triggerEvent,"key")));
			action.addAction(new TimelineAction(powerSwitch, "on", "off"));
			action.addAction(new AnimationAction(pinata, Grief, null, 50));
			// close on first guy
			action.addAction(new CallFunctionAction(closeMachine));
			action.addAction(new WaitAction(1.8));
			action.addAction(new CallFunctionAction(shakeMachine));
			action.addAction(new WaitAction(1.6));
			action.addAction(new CallFunctionAction(makeHenchbot));
			action.addAction(new CallFunctionAction(openMachine));
			action.addAction(new WaitAction(1));
			// dump new robot in crate
			action.addAction(new CallFunctionAction(movePinata));
			action.addAction(new WaitAction(1.4));
			action.addAction(new CallFunctionAction(dropPinata));
			action.addAction(new WaitAction(1.5));
			action.addAction(new PanAction(hench1));
			action.addAction(new TalkAction(hench1,"next"));
			action.addAction(new PanAction(wizard));
			// bring in the unlucky wizard
			action.addAction(new CallFunctionAction(moveWizard));
			action.addAction(new WaitAction(1.7));
			action.addAction(new TalkAction(wizard,"soda"));
			action.addAction(new AnimationAction(hench0, PointItem, "pointing"));
			action.addAction(new CallFunctionAction(Command.create(shellApi.triggerEvent,"key")));
			action.addAction(new TimelineAction(powerSwitch, "on", "off"));
			action.addAction(new CallFunctionAction(shakeMachine));
			action.addAction(new WaitAction(1.6));
			action.addAction(new CallFunctionAction(zapSoda)).noWait = true;
			action.addAction(new TalkAction(wizard,"now")).noWait = true;
			action.addAction(new AnimationAction(wizard, Grief,"",50));
			action.addAction(new WaitAction(0.6));
			action.addAction(new CallFunctionAction(closeMachine));
			action.addAction(new WaitAction(1.1));
			action.addAction(new CallFunctionAction(shakeMachine));
			action.addAction(new WaitAction(1.5));
			action.addAction(new PanAction(machine));
			action.addAction(new CallFunctionAction(breakMachine));
			action.addAction(new CallFunctionAction(openMachine));
			// broken machine	
			action.addAction(new TalkAction(hench0,"bio"));
			action.addAction(new PanAction(hench1));
			action.addAction(new MoveAction(hench1,new Point(960,930),new Point(30,80)));
			action.addAction(new TalkAction(hench1,"wire"));
			action.addAction(new WaitAction(0.4));
			action.addAction(new CallFunctionAction(blowupHench));
			action.addAction(new WaitAction(3));
			action.addAction(new MoveAction(hench0,new Point(885,930),new Point(30,100),1));
			action.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection, hench0, true)));
			action.addAction(new TalkAction(hench0,"wrench"));
			action.addAction(new PanAction(wizard));
			action.addAction(new MoveAction(hench0,new Point(1755,650),new Point(50,50)));
			action.addAction(new CallFunctionAction(Command.create(ToolTipCreator.removeFromEntity,wizard)));
			action.addAction(new CallFunctionAction(Command.create(removeEntity,hench0)));
			action.addAction(new TalkAction(wizard,"help"));
			action.addAction(new PanAction(player));
			action.addAction(new CallFunctionAction(machineBroken));
			SceneUtil.addTimedEvent(this, new TimedEvent(.1,1,action.execute));
		}
		
		private function zapSoda():void
		{
			var can:Entity = SkinUtils.getSkinPartEntity(wizard, SkinUtils.ITEM);
			electrifyEntity(can);
			// SOUND
			AudioUtils.playSoundFromEntity(machine, ZAP, 500, 1.5, 1.5);
		}
		
		private function blowupHench():void
		{			
			CharUtils.setAnim(hench1, PlacePitcher);
			CharUtils.getTimeline(hench1).handleLabel("trigger2",CharUtils.getTimeline(hench1).stop);
			// explode
			var sparks:Emitter2D = new Emitter2D();
			sparks.counter = new Blast( 24 );
			sparks.addInitializer( new ImageClass( Blob, [ 5.5 ], true ));
			sparks.addInitializer( new ColorInit( 0xffffff, 0xFFFBB0 ));
			sparks.addInitializer( new AlphaInit( .8, 1 ));
			var clip:MovieClip = EntityUtils.getDisplayObject(hench1) as MovieClip;
			sparks.addInitializer( new Position( new PointZone(new Point(clip.x,clip.y))));
			sparks.addInitializer( new Velocity( new DiscZone(new Point(0,0),200,100)));
			sparks.addInitializer( new Lifetime( 0.3, 0.6 ));
			sparks.addAction( new Age( Quadratic.easeIn ));
			sparks.addAction( new Move());
			sparks.addAction( new Accelerate( 0, 110 ));
			sparks.addAction( new RandomDrift( 30, 20 ));
			sparks.addAction( new Fade( 1, 0 ));
			sparks.addAction( new ScaleImage( 0.9, .3 ));
			
			EmitterCreator.create( this, _hitContainer, sparks, 0, -20, hench1 );
			
			electrifyEntity(hench1);
			shakeHench();
			//SOUND		
			AudioUtils.playSoundFromEntity(hench1, SHOCK_BOT, 500, 1.5, 1.5, null, true);
		}
		
		private function shakeHench():void
		{
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-3, -3, 3, 3));
			shake.active = true;
			hench1.add(shake);
			hench1.add(new SpatialAddition());
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,Command.create(stopHenchShake,shake)));
		}		
		
		private function stopHenchShake(shake:ShakeMotion):void
		{
			shake.active = false;
			CharUtils.setAnim(hench1, game.data.animation.entity.character.Sleep);
			SkinUtils.setSkinPart(hench1, SkinUtils.EYES, "hypnotized");
			
			Audio(hench1.get(Audio)).stop(SHOCK_BOT);
			AudioUtils.playSoundFromEntity(hench1, EXPLODE);
			
			removeElectrify(hench1);
		}		
		
		private function closeMachine():void
		{
			Timeline(machine.get(Timeline)).gotoAndPlay("close");
			AudioUtils.playSoundFromEntity(machine, MACHINE_CLOSE, 500, 0, 1);
		}
		private function openMachine():void
		{
			Timeline(machine.get(Timeline)).gotoAndPlay("open");
			AudioUtils.playSoundFromEntity(machine, MACHINE_CLOSE, 500, 0, 1);
		}
		
		private function machineBroken():void
		{
			shellApi.completeEvent(_events.MACHINE_BROKEN);
		}
		
		private function moveWizard():void
		{
			startBelt0();
			startBelt1();
			TweenUtils.entityTo(wizard, Spatial,1.4,{x:730,y:745,onComplete:stopBelts});
		}
		
		private function stopBelts():void
		{
			stopBelt0();
			stopBelt1();
		}
		
		private function movePinata():void
		{
			startBelt1();
			TweenUtils.entityTo(pinata, Spatial,1.4,{x:1075,y:750,onComplete:stopBelt1});
		}
		
		private function dropPinata():void
		{
			// fall into bot bucket
			TweenUtils.entityTo(pinata, Spatial,1.15,{x:1200,y:865,rotation:110,onComplete:clearPinata});
		}
		private function clearPinata():void
		{	
			ToolTipCreator.removeFromEntity(pinata);
			removeEntity(pinata);
			AudioUtils.playSoundFromEntity(getEntityById("crate"), DROP_IN_BIN, 600,1.1,1.1);
		}
		
		private function startBelt0():void
		{
			Timeline(belt0.get(Timeline)).play();
			AudioUtils.playSoundFromEntity(belt0, BELT_START,600,1);
		}
		
		private function stopBelt0():void
		{
			Timeline(belt0.get(Timeline)).stop();
		}
		
		private function startBelt1():void
		{
			Timeline(belt1.get(Timeline)).play();
			AudioUtils.playSoundFromEntity(belt1, BELT_START,600,1);
		}
		
		private function stopBelt1():void
		{
			Timeline(belt1.get(Timeline)).stop();
		}
		
		private function makeHenchbot():void
		{
			var look:LookData = SkinUtils.getLook(hench0);	
			SkinUtils.applyLook(pinata,look,true);
			CharUtils.freeze(pinata, true);
		}
		
		private function shakeMachine():void
		{
			var shake:ShakeMotion = machine.get(ShakeMotion);
			shake.active = true;
			AudioUtils.playSoundFromEntity(machine, MACHINE_SHAKE,600,1);
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,Command.create(stopShake,shake)));
		}
		
		private function stopShake(shake:ShakeMotion):void
		{
			shake.active = false;
		}
		
		private function breakMachine():void
		{
			// smoke particle burst
			var smoke:Emitter2D = new Emitter2D();
			smoke.counter = new Blast( 60 );
			smoke.addInitializer( new ImageClass( Blob, [ 8 ], true ));
			smoke.addInitializer( new ColorInit( 0x111111, 0x999999 ));
			smoke.addInitializer( new AlphaInit( .8, 1 ));
			var clip:DisplayObjectContainer = _hitContainer["machine0"];
			var rect:Rectangle = clip.getBounds(_hitContainer);
			smoke.addInitializer( new Position( new RectangleZone( rect.left, rect.top, rect.right, rect.bottom )));
			smoke.addInitializer( new Velocity( new LineZone( new Point( 0, -120 ), new Point( 0, -80 ))));
			smoke.addInitializer( new Lifetime( .5, 1.5 ));
			smoke.addAction( new Age( Quadratic.easeIn ));
			smoke.addAction( new Move());
			smoke.addAction( new Accelerate( 0, -80 ));
			smoke.addAction( new RandomDrift( 15, 15 ));
			smoke.addAction( new Fade( 1, 0 ));
			smoke.addAction( new ScaleImage( 1, .4 ));
			EmitterCreator.create( this, _hitContainer, smoke, 0, -20 );
			AudioUtils.playSoundFromEntity(machine, MACHINE_BREAK,600,1);
			
			Timeline(sparks.get(Timeline)).play();
			Timeline(sparks.get(Timeline)).handleLabel("zap",sparkSound,false);
			Timeline(sparks.get(Timeline)).handleLabel("zap2",sparkSound,false);
			Timeline(wires.get(Timeline)).gotoAndStop("broke");
			//addMachineSparks();
		}
		
//		private function addMachineSparks():void
//		{
//			var clip:MovieClip = _hitContainer["sparks"];
//			_sparkSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
//			var sparkEntity:Entity = makeEntity( clip, true, _sparkSequence );
//	//		sparkEntity.add(new Id("spark"));
//			// click
//			InteractionCreator.addToEntity( sparkEntity, [InteractionCreator.CLICK]);
//			ToolTipCreator.addToEntity( sparkEntity );
//			// charge glove on sparky wires	
//			var sceneInteraction:SceneInteraction = new SceneInteraction();	
//			sceneInteraction.offsetY = 100;
//			sceneInteraction.minTargetDelta = new Point(30,120);
//			sceneInteraction.reached.add(sparkReached);
//			sparkEntity.add( sceneInteraction );	
//			
//			//SOUND intermitent sparks
//			
//		}
		
		private function sparkReached(spark:Entity, pl:Entity):void
		{
			if(shellApi.checkEvent(_events.GAUNTLETS_CHARGED))
			{
				Dialog(player.get(Dialog)).sayById("charged");
			}
			else if(shellApi.checkEvent(_events.MACHINE_BROKEN))
			{
				// charge glove or comment about power
				if( CharUtils.hasSpecialAbility( shellApi.player, PowerGlove))
				{
					//approachGlove();
					chargeGlove();
				}
				else
				{
					Dialog(player.get(Dialog)).sayById("power");
				}
			}
			
		}
		
		/*		private function approachGlove(...p):void
		{
		if( CharUtils.getStateType( player ) == CharacterState.STAND )
		{
		SceneUtil.lockInput( this );
		var spark:Entity = getEntityById("spark");
		var pos:Point = EntityUtils.getPosition(spark);
		CharUtils.moveToTarget(player, pos.x, pos.y+100,false, chargeGlove, new Point(30,100));
		}
		}*/
		
		private function chargeGlove(...p):void
		{
			// charge up gauntlets
			shellApi.completeEvent( _events.GAUNTLETS_CHARGED );
			CharUtils.setAnim(player, PlacePitcher);
			CharUtils.getTimeline(player).handleLabel("trigger2", runSparks);
		}
		
		private function runSparks():void
		{
			CharUtils.getTimeline(player).stop();
			var specialControl:SpecialAbilityControl = player.get( SpecialAbilityControl ) as SpecialAbilityControl;
			
			var powerGlove:PowerGlove = specialControl.getSpecialByClass( PowerGlove ).specialAbility as PowerGlove;	// TODO ::type won't do... need to test class
			powerGlove.chargeUp();
			
			electrifyEntity(player);
			AudioUtils.playSoundFromEntity(player, CHARGE, 600, 1.3, 1.3);
			Dialog(player.get(Dialog)).complete.addOnce(deZap);
		}
		
		private function deZap(...p):void
		{
			CharUtils.getTimeline(player).play();
			shellApi.showItem(_events.GAUNTLETS, null);
			removeElectrify(player);
		}
		
		override protected function freeActor():void
		{
			// lock, talk, escape thru vent, unlock
			var actions:ActionChain = new ActionChain(this);
			var dialog:Dialog = getEntityById( "goldFace" ).get( Dialog );
			dialog.allowOverwrite = true;
			
			actions.lockInput = true;
			actions.addAction(new PanAction(goldface));
			actions.addAction(new TalkAction(goldface,"freedom"));
			actions.addAction(new CallFunctionAction(clearAnims));
			actions.addAction(new MoveAction(goldface,new Point( 1480, 400)));
			actions.addAction(new MoveAction(goldface,new Point( 1480, 150)));
			actions.addAction(new WaitAction(1));
			actions.addAction(new CallFunctionAction(goldFaceLeft));
			actions.addAction(new PanAction(player));
			actions.execute();
		}
		
		private function clearAnims():void
		{
			CharUtils.setAnim(goldface, Stand,false, 30, 0, true);
		}
		
		private function goldFaceLeft(...p):void
		{
			ToolTipCreator.removeFromEntity(goldface);
			removeEntity(goldface);
			shellApi.completeEvent(_events.GOLD_FACE_RESCUED);
		}
		
		private function setupPushBoxes():void
		{
			_sceneObjectCreator = new SceneObjectCreator();
			
			super.addSystem(new SceneObjectHitRectSystem());
			super.player.add(new SceneObjectCollider());
			super.player.add(new RectangularCollider());
			super.player.add( new Mass(100) );
			
			var box:Entity;
			var clip:MovieClip;
			var bounds:Rectangle;
			var wrapper:BitmapWrapper;
			
			for (var i:int = 0; _hitContainer["box"+i] != null; i++) 
			{
				clip = _hitContainer["bounds"+i];
				bounds = new Rectangle(clip.x,clip.y,clip.width,clip.height);
				_hitContainer.removeChild(clip);
				clip = _hitContainer["box"+i];
			///	if(PerformanceUtils.qualityLevel <  PerformanceUtils.QUALITY_HIGH){
				wrapper = super.convertToBitmapSprite( clip, null, true, PerformanceUtils.defaultBitmapQuality);
			///		BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			///	}
				box = _sceneObjectCreator.createBox( wrapper.sprite,0,super.hitContainer,NaN,NaN,null,null,bounds,this,null,null,400);
				
				SceneObjectMotion(box.get(SceneObjectMotion)).rotateByPlatform = false;
				box.add(new Id("box"+i));
				box.add(new WallCollider());
				box.add(new PlatformCollider());
				if(i == 0){
					var ceil:Entity = getEntityById("blocker0");
					Display(ceil.get(Display)).isStatic = false;
					var folo:FollowTarget = new FollowTarget(box.get(Spatial));
					folo.offset = new Point(0,54.5);
					ceil.add(folo);
				}else if(i == 1){
					this.addSystem(new ThresholdSystem()); 
					var thresh:Threshold = new Threshold("y",">");
					thresh.threshold = 500;
					thresh.entered.addOnce(Command.create(pushBoundsShift, 2));
					box.add(thresh);
				}
				// box sounds
				var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
				audioGroup.addAudioToEntity(box, "box");
				new HitCreator().addHitSoundsToEntity(box,audioGroup.audioData,shellApi,"box");
			}
		}
		
		// update bounds as box falls down
		private function pushBoundsShift(i:int):void
		{
			var clip:MovieClip = _hitContainer["bounds"+i];
			var bounds:Rectangle = new Rectangle(clip.x,clip.y,clip.width,clip.height);
			_hitContainer.removeChild(clip);
			var box:Entity = getEntityById("box1");
			MotionBounds(box.get(MotionBounds)).box = bounds;
			var thresh:Threshold = box.get(Threshold);
			if(i==1){
				thresh.threshold = 500;
			}
			else if(i==2){
				thresh.threshold = 711;
			}
			if(i < 3){
				thresh.entered.addOnce(Command.create(pushBoundsShift, i+1));
			}
		}
		
		private function makeEntity( clip:MovieClip, play:Boolean = true, sequence:BitmapSequence = null ):Entity
		{
			if( sequence )
			{
				var target:Entity = EntityUtils.createMovingTimelineEntity(this, clip, null, play);
				target = BitmapTimelineCreator.convertToBitmapTimeline(target, clip, true, sequence, PerformanceUtils.defaultBitmapQuality + 0.3);
			}
			else
			{
				var wrapper:BitmapWrapper = super.convertToBitmapSprite( clip, null, true, PerformanceUtils.defaultBitmapQuality + 0.3);
				target = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			}
			
			target.add( new Id( clip.name ));
			return target; 
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this, true);
		}
		
		private function electrifyEntity(entity:Entity):void
		{
			if( PlatformUtils.isDesktop )
			{
				var display:Display = entity.get( Display );
				var electrify:ElectrifyComponent = new ElectrifyComponent();	
				
				// Add flashy filters to display
				var colorFill:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 100, 100, 1, 1, true );
				var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1.5, 1);
				var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true);			
				var filters:Array = new Array( colorFill, whiteOutline, colorGlow );
				display.displayObject.filters = filters;		
				
				// Electrify
				for( var number:int = 0; number < 10; number ++ )
				{
					var sprite:Sprite = new Sprite();
					var startX:Number = Math.random() * 120 - 60;
					var startY:Number = Math.random() * 280 - 140;				
					sprite.graphics.lineStyle( 1, 0xFFFFFF );
					sprite.graphics.moveTo( startX, startY );
					electrify.sparks.push( sprite );
					electrify.lastX.push( startX );
					electrify.lastY.push( startY );
					electrify.childNum.push( display.displayObject.numChildren );
					display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
				}			
				entity.add( electrify );
			}
			//SceneUtil.addTimedEvent(this, new TimedEvent(2,1,Command.create(removeElectrify,entity)));
		}
		
		private function removeElectrify(entity:Entity):void
		{
			var display:Display = entity.get( Display );
			if( PlatformUtils.isDesktop )
			{
				display.displayObject.filters = new Array();
				
				for( var number:int = 0; number < 9; ++number )
				{
					if(display.displayObject.numChildren > 0){
						display.displayObject.removeChildAt( display.displayObject.numChildren - 1 );
					}
				}
				
				entity.remove( ElectrifyComponent );
			}
		}
	}
}