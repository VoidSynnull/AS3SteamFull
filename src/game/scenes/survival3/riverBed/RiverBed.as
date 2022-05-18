package game.scenes.survival3.riverBed
{
	import com.greensock.easing.Bounce;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
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
	
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Platform;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.LabelHandler;
	import game.data.animation.entity.character.Knock;
	import game.components.hit.HitTest;
	import game.systems.hit.HitTestSystem;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival3.riverBed.popups.CoinPopup;
	import game.scenes.survival3.shared.Survival3Scene;
	import game.scenes.survival3.shared.components.RadioSignal;
	import game.components.hit.SeeSaw;
	import game.systems.hit.SeeSawSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class RiverBed extends Survival3Scene
	{
		public function RiverBed()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival3/riverBed/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var survival:Survival3Events;
		// all assets ready
		override public function loaded():void
		{
			survival = events as Survival3Events;
			shellApi.eventTriggered.add(onEventTriggered);
			super.loaded();
			createSeeSaw();
			setUpWingInTree();
			setUpIce();
			setUpCutTree();
			setUpProp();
			
			RadioSignal(player.get(RadioSignal)).groundLevel += 1500;
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == survival.USE_SAW)
			{
				useSaw();
			}
			else if(event == survival.RADIO)
			{
				var wrongRadio:Dialog = player.get(Dialog);
				wrongRadio.sayById("radio_wrong");
			}
		}
		
		private function useSaw():void
		{
			if(shellApi.checkEvent(survival.CUT_DOWN_TREE))
				return;
			
			var useDistance:Number = 250;
			var playerSpatial:Spatial = player.get(Spatial);
			var tree:Entity = getEntityById("cutClick");
			var treeSpatial:Spatial = tree.get(Spatial);
			if(Math.abs(playerSpatial.x - treeSpatial.x) < useDistance)
			{
				var interaction:SceneInteraction = tree.get(SceneInteraction);
				interaction.activated = true;
				interaction.autoSwitchOffsets = false;
				interaction.reached.removeAll();
				interaction.reached.add(cutTree);
			}
		}
		
		private function setUpProp():void
		{
			var clip:MovieClip = _hitContainer["prop"];
			var propClip:MovieClip = clip["prop"];
			var prop:Entity = EntityUtils.createSpatialEntity(this, propClip, clip);
			TimelineUtils.convertClip(propClip, this, prop);
		}
		
		private function setUpCutTree():void
		{
			var spatial:Spatial;
			var interaction:SceneInteraction;
			
			var clip:MovieClip = _hitContainer["treeCover"];
			var cover:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			cover.add(new Id(clip.name));
			
			clip = _hitContainer["treeCut"];
			clip.mouseEnabled = false;
			var tree:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			tree.add(new Id(clip.name));
			TimelineUtils.convertAllClips(clip, tree, this, false);
			
			clip = _hitContainer["purseHit"];
			var purse:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			purse.add(new Id(clip.name));
			Display(purse.get(Display)).alpha = 0;
			
			clip = _hitContainer["cut"];
			
			if(!shellApi.checkEvent(survival.CUT_DOWN_TREE))
			{
				getEntityById("fallenTree").remove(Platform);
				var cutClick:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				cutClick.add(new Id("cutClick")).add(new SceneInteraction());
				InteractionCreator.addToEntity(cutClick, ["click"], clip);
				interaction = cutClick.get(SceneInteraction);
				interaction.minTargetDelta.x = 25;
				interaction.minTargetDelta.y = 100;
				interaction.offsetX = 25;
				interaction.validCharStates = new<String>[ CharacterState.STAND, CharacterState.WALK ];
				interaction.reached.add(commentOnTree);
				ToolTipCreator.addToEntity(cutClick);
			}
			else
			{
				_hitContainer.removeChild(clip);
				spatial = tree.get(Spatial);
				spatial.x = 2450;
				spatial.y = 1165;
				spatial.rotation = -101;
				
				var wing:Entity = getEntityById("seesaw");
				spatial = wing.get(Spatial);
				spatial.rotation = 24;
				wing.remove(SeeSaw);
				
				wing = getEntityById("planeWing");
				spatial = wing.get(Spatial);
				spatial.rotation = 24;
				
				removeEntity(cover);
				
				if(!shellApi.checkHasItem(survival.PENNY))
					setUpPurse();
			}
		}
		
		private function commentOnTree(...args):void
		{
			Dialog(player.get(Dialog)).sayById("cut_tree");
		}
		
		private function setUpPurse():void
		{
			var purse:Entity = getEntityById("purseHit");
			purse.add(new SceneInteraction());
			SceneInteraction(purse.get(SceneInteraction)).reached.add(openPurse);
			InteractionCreator.addToEntity(purse, ["click"], EntityUtils.getDisplayObject(purse));
			ToolTipCreator.addToEntity(purse);
		}
		
		private function openPurse(player:Entity, purse:Entity):void
		{
			var popup:CoinPopup = addChildGroup(new CoinPopup(overlayContainer)) as CoinPopup;
			popup.removed.add(closedPopup);
		}
		
		private function closedPopup(...args):void
		{
			if(shellApi.checkHasItem(survival.PENNY))
				removeEntity(getEntityById("purseHit"));
		}
		
		private function cutTree(...args):void
		{
			SceneUtil.lockInput(this);
			CharUtils.lockControls(player);
			CharUtils.setDirection(player, false);
			var sequence:Vector.<Class> = new Vector.<Class>();
			sequence.push(Knock, Knock, Knock);
			CharUtils.setAnimSequence(player,sequence);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM2, "armyknife", false);
			labelHandler = Timeline(player.get(Timeline)).handleLabel("ending", timber, false);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "cut_wood_01_loop.mp3", 1, true);
		}
		private var labelHandler:LabelHandler;
		private var hacks:int  = 0;
		private function timber():void
		{
			++hacks;
			if(hacks < 3)
				return;
			
			labelHandler.listenOnce = true;
			
			var tree:Entity = getEntityById("treeCut");
			
			SceneUtil.setCameraTarget(this, getEntityById("purseHit"));
			
			shellApi.camera.camera.scaleTarget = .75;
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, dropInToPlace));
			tree = Children(tree.get(Children)).children[0];
			var time:Timeline = tree.get(Timeline);
			time.handleLabel("ending", Command.create(treeInPlace, time));
			time.play();
			
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "cut_wood_01_loop.mp3");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_break_06.mp3");
		}
		
		private function dropInToPlace():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_break_01.mp3");
			TweenUtils.entityTo(getEntityById("seesaw"), Spatial, .5, {rotation:24, ease:Bounce.easeOut});
		}
		
		private function treeInPlace(timeline:Timeline):void
		{
			timeline.gotoAndStop(timeline.currentIndex);
			removeEntity(getEntityById("treeCover"));
			removeEntity(getEntityById("cutClick"));
			CharUtils.lockControls(player, false, false);
			SceneUtil.lockInput(this, false);
			getEntityById("fallenTree").add(new Platform());
			getEntityById("seesaw").remove(SeeSaw);
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
			shellApi.camera.camera.scaleTarget = 1;
			CharUtils.setState(player, CharacterState.LAND);
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM2, false);
			FSMControl(player.get(FSMControl)).active = true;
			setUpPurse();
			shellApi.completeEvent(survival.CUT_DOWN_TREE);
		}
		
		private var iceSpawnX:Number;
		
		private function setUpIce():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "river_hard_01_loop.mp3", 1, true);
			addSystem(new WaveMotionSystem());
			addSystem(new ThresholdSystem());
			iceSpawnX = _hitContainer["iceSpawn"].x;
			for(var i:int = 0; i <= 5; i++)
			{
				var clip:MovieClip = _hitContainer["ice"+i];
				var ice:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				
				var threshold:Threshold = new Threshold("x", "<");
				threshold.threshold = -100;
				threshold.entered.add(Command.create(iceOffScreen, ice));
				
				var data:WaveMotionData = new WaveMotionData("y", 7.5,.1);
				var bob:WaveMotion = new WaveMotion();
				bob.add(data);
				
				ice.add(threshold).add(new Id(clip.name)).add(new SpatialAddition()).add(bob);
				ice.remove(Sleep);
				Motion(ice.get(Motion)).velocity = new Point(- 400, 0);
			}
		}
		
		private function iceOffScreen(ice:Entity):void
		{
			Spatial(ice.get(Spatial)).x = iceSpawnX;
		}
		
		private function setUpWingInTree():void
		{
			addSystem(new HitTestSystem());
			
			var clip:MovieClip = _hitContainer["wingTip"];
			var wing:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(clip, this, wing, null, false);
			var time:Timeline = wing.get(Timeline);
			time.labelReached.add(tippingAnimationHandler);
			wing.add(new Id(clip.name));
			
			var tipOfWing:Entity = getEntityById("tipWing");
			var hit:HitTest = new HitTest();
			hit.onEnter.add(tipWing);
			tipOfWing.add(hit);
			
			if(shellApi.checkEvent(survival.TIPPED_WING))
			{
				removeEntity(tipOfWing);
				removeEntity(wing);
				removeEntity(getEntityById("wing"));
			}
		}
		
		private function tippingAnimationHandler(label:String):void
		{
			if(label == "ending")
				tippedWing();
			if(label == "landsInWater")
				splash();
			if(label == "hitsRock")
				crash();
		}
		
		private function crash():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "metal_impact_20.mp3");
		}
		
		private function splash():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "big_splash_01.mp3");
		}
		
		private function tipWing(...args):void
		{
			SceneUtil.lockInput(this);
			removeEntity(getEntityById("tipWing"));
			Timeline(getEntityById("wingTip").get(Timeline)).play();
			removeEntity(getEntityById("wing"));
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "heavy_metal_drag_01.mp3");
		}
		
		private function tippedWing():void
		{
			var wing:Entity = getEntityById("wingTip");
			var time:Timeline = wing.get(Timeline);
			time.gotoAndStop(time.currentIndex);
			removeEntity(wing,true);
			wing = getEntityById("planeWing");
			Display(wing.get(Display)).visible = true;
			wing = getEntityById("seesaw");
			wing.add(new Platform());
			shellApi.completeEvent(survival.TIPPED_WING);
			SceneUtil.lockInput(this, false);
		}
		
		private function createSeeSaw():void
		{
			var clip:MovieClip = _hitContainer["planeWing"];
			clip.mouseEnabled = false;
			var seesaw:Entity = getEntityById("seesaw");
			var edge:Edge = new Edge();
			edge.unscaled = clip.getBounds(clip);
			seesaw.add(edge).add(new SeeSaw(20,20,-20, 20, getEntityById("planeWing")));
			Display(seesaw.get(Display)).alpha = 0;
			player.add(new Mass(30));
			
			addSystem(new SeeSawSystem(), SystemPriorities.move);
			
			if(!shellApi.checkEvent(survival.TIPPED_WING))
			{
				seesaw.remove(Platform);
				Display(getEntityById("planeWing").get(Display)).visible = false;
			}
		}
	}
}