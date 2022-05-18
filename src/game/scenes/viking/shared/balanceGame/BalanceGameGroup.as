package game.scenes.viking.shared.balanceGame
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.particles.emitter.characterAnimations.Sweat;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.viking.VikingEvents;
	import game.scenes.viking.diningHall.DiningHall;
	import game.scenes.viking.fortress.Fortress;
	import game.scenes.viking.river.River;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.osflash.signals.Signal;
	
	public class BalanceGameGroup extends Group
	{
		
		private var GROUP_ID:String = "balanceGameGroup";
		
		private static const SEGMENT_PATH:String = 'scenes/viking/shared/balance/segment.swf';
		private static const FUR_PATH:String = 'scenes/viking/shared/balance/furs.swf';
		
		private var _container:DisplayObjectContainer;
		private var _events:VikingEvents;
		private var _player:Entity;
		
		private var mya:Entity;
		private var oliver:Entity;
		private var jorge:Entity;
		private var segmentChain:Entity;
		private var inFear:Boolean;
		private var sweatEmitter:Entity;
		
		public var balanceGameGroupReady:Signal;
		private var playerHiddenParts:Array;
		
		
		public function BalanceGameGroup(container:DisplayObjectContainer)
		{
			this.id = GROUP_ID;
			_container = container;
			
			balanceGameGroupReady = new Signal();
		}
		
		override public function added():void
		{
			_player = PlatformerGameScene(this.parent).player;
			shellApi = parent.shellApi;
			
			playerHiddenParts = [SkinUtils.HEAD, SkinUtils.HAIR, SkinUtils.MARKS, SkinUtils.FACIAL, SkinUtils.MOUTH, SkinUtils.EYES, SkinUtils.ITEM, SkinUtils.ITEM2, SkinUtils.BODY, SkinUtils.OVERSHIRT, SkinUtils.OVERPANTS];
			
			shellApi.loadFile( shellApi.assetPrefix + SEGMENT_PATH, setupBalance);
			
			super.added();
		}
		
		private function attachFurs(fursClip:MovieClip):void
		{
			var pieceClip:* = fursClip["fur0"];
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
			{
				pieceClip = DisplayUtils.convertToBitmapSprite(pieceClip, null, PerformanceUtils.defaultBitmapQuality, true, null).sprite;
			}
			var piece:Entity = EntityUtils.createMovingEntity(this,pieceClip);		
			var seg:Entity = getEntityById("seg0");
			piece.add(new Id("fur0"));
			attachChar(piece, seg);
			
			pieceClip = fursClip["fur1"];
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
			{
				pieceClip = DisplayUtils.convertToBitmapSprite(pieceClip, null, PerformanceUtils.defaultBitmapQuality, true, null).sprite;
			}
			piece = EntityUtils.createMovingEntity(this,pieceClip);	
			seg = getEntityById("seg1");
			piece.add(new Id("fur1"));
			attachChar(piece, seg);
			
			pieceClip = fursClip["fur2"];
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
			{
				pieceClip = DisplayUtils.convertToBitmapSprite(pieceClip, null, PerformanceUtils.defaultBitmapQuality, true, null).sprite;
			}
			piece = EntityUtils.createMovingEntity(this,pieceClip);
			seg = getEntityById("seg2");
			piece.add(new Id("fur2"));
			attachChar(piece, seg);
			
			SkinUtils.hideSkinParts(_player, playerHiddenParts, true);
			
			balanceGameGroupReady.dispatch();
		}
		
		private function setupBalance(segmentClip:MovieClip):void
		{
			this.addSystem(new BalanceGameSystem());
			this.addSystem(new ThresholdSystem());
			
			mya = parent.getEntityById("mya");
			oliver = parent.getEntityById("oliver");
			var helm:Entity = SkinUtils.getSkinPartEntity(oliver, SkinUtils.HAIR);
			Spatial(helm.get(Spatial)).scale += 0.3;
			jorge = parent.getEntityById("jorge");
			
			ToolTipCreator.removeFromEntity(jorge);
			ToolTipCreator.removeFromEntity(mya);
			ToolTipCreator.removeFromEntity(oliver);
			
			Motion(_player.get(Motion)).maxVelocity.x = 200;
			CharacterMotionControl(_player.get(CharacterMotionControl)).maxVelocityX = 200;
			
			FSMControl(_player.get(FSMControl)).removeState(CharacterState.JUMP);
			EntityUtils.position(_player, 3200, _player.get(Spatial).y);			
			
			// make chain of balance nodes, invisible
			segmentChain = EntityUtils.createMovingEntity(this,segmentClip, _container);
			EntityUtils.positionByEntity(segmentChain,_player);	
			var follow:FollowTarget = new FollowTarget(_player.get(Spatial));
			follow.offset = new Point(0,-10);
			segmentChain.add(follow);
			var stack:BalanceSegmentComp = new BalanceSegmentComp();
			segmentChain.add(stack);
			stack.failSignal.addOnce(balanceFailed);	
			stack.warningSignal.add(tiltWarningHandler);
			
			var link:BalanceSegment;
			var segment:Entity = EntityUtils.createMovingEntity(this,segmentClip.seg0, segmentClip);
			link = new BalanceSegment();				
			stack.segments.push(segment);
			segment.add(link);
			segment.add(new Id("seg0"));
			
			segment = EntityUtils.createMovingEntity(this,segmentClip.seg0.seg1, segmentClip.seg0);
			link = new BalanceSegment();				
			stack.segments.push(segment);
			segment.add(link);
			segment.add(new Id("seg1"));
			//attachChar(mya, segment);
			
			segment = EntityUtils.createMovingEntity(this,segmentClip.seg0.seg1.seg2, segmentClip.seg0.seg1);
			link = new BalanceSegment();				
			stack.segments.push(segment);
			segment.add(link);
			segment.add(new Id("seg2"));
			//attachChar(jorge, segment);
			
			segment = EntityUtils.createMovingEntity(this,segmentClip.seg0.seg1.seg2.seg3, segmentClip.seg0.seg1.seg2);
			link = new BalanceSegment();				
			stack.segments.push(segment);
			segment.add(link);
			segment.add(new Id("seg3"));
			attachChar(oliver, segment);
			
			// player moving left addes to clockwise tilt, player moving right adds to counterclockwise tilt
			// sucess threshold!
			var thresh:Threshold = new Threshold("x","<");
			thresh.threshold = 600;
			thresh.entered.addOnce(balanceComplete);
			_player.add(thresh);
			
			// hide giant
			//var giant:Entity = parent.getEntityById("giant");
			//Display(giant.get(Display)).visible = false;
			removeEntity(parent.getEntityById("giant"));
			
			var giant:Entity = parent.getEntityById("giant2");
			Display(giant.get(Display)).visible = false;
			
			Display(mya.get(Display)).visible = false;
			Display(jorge.get(Display)).visible = false;
			
			shellApi.loadFile( shellApi.assetPrefix + FUR_PATH, attachFurs);
		}
		
		// olvier makes concerned face when tilted too far
		private function tiltWarningHandler(inWarning:Boolean):void
		{
			if(inWarning && !inFear){
				// fear face
				SkinUtils.setSkinPart(oliver,SkinUtils.MOUTH,"angry",false);
				addSweat(oliver);
				inFear = true;
			}
			else if(!inWarning && inFear){
				// normal face
				SkinUtils.setSkinPart(oliver,SkinUtils.MOUTH,"comic_oliver",false);
				removeSweat(oliver);
				inFear = false;
			}
		}
		
		private function removeSweat(ent:Entity):void
		{
			if(sweatEmitter){
				Sweat(sweatEmitter.get(Emitter).emitter).counter.stop();
			}
		}
		
		private function addSweat(character:Entity):void
		{
			var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.HEAD_JOINT ).get(Spatial);
			
			var sweat:Sweat = new Sweat();
			sweat.init();
			sweat.addInitializer( new ImageClass( Dot, [6], true ) );
			sweat.counter.stop();
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			sweatEmitter = EmitterCreator.create( group, container, sweat, 0, 0, character, "sweat", followTarget);
		}
		
		private function attachChar(char:Entity, segment:Entity):void
		{
			char.add(new Sleep(false, true));
			//merge npc graphics with target
			var segDisplay:Display = EntityUtils.getDisplay(segment);
			var charDisplay:Display = EntityUtils.getDisplay(char);
			var charHolder:MovieClip = segDisplay.displayObject.getChildByName("charHolder") as MovieClip;
			charDisplay.setContainer(charHolder);
			EntityUtils.position(char, 0, 0);
		}
		
		private function balanceFailed(...p):void
		{
			// stop motion, reload scene from right side
			BalanceSegmentComp(segmentChain.get(BalanceSegmentComp)).tilting  = false;
			
			SceneUtil.lockInput(this, true);
			
			var cook:Entity = parent.getEntityById("cook");
			
			var actions:ActionChain = new ActionChain(Scene(parent));
			
			actions.addAction(new PanAction(cook));
			actions.addAction(new AnimationAction(cook,Stomp));
			actions.addAction(new TalkAction(cook,"catch"));
			actions.addAction(new WaitAction(1));
			actions.addAction(new CallFunctionAction(Command.create(shellApi.loadScene,DiningHall)));
			
			actions.execute();
		}		
		
		
		private function balanceComplete(...p):void
		{
			DiningHall(parent).pauseJokers();
			
			BalanceSegmentComp(segmentChain.get(BalanceSegmentComp)).tilting  = false;
			
			SceneUtil.lockInput(this, true);

			var giant:Entity = parent.getEntityById("giant2");
			Display(giant.get(Display)).visible=true;
			var rigAnim:RigAnimation = CharUtils.getRigAnim( giant );
			rigAnim.manualEnd = true;
			CharacterGroup( getGroupById("characterGroup") ).addFSM( giant );
			CharUtils.setAnim(giant, Stand, false, 0, 0, true);
			
			var vik1:Entity = parent.getEntityById("underling_1");
			var vik2:Entity = parent.getEntityById("underling_2");
			var drain:Entity = parent.getEntityById("doorRiver");
			
			var actions:ActionChain = new ActionChain(Scene(parent));
			
			actions.addAction(new TalkAction(_player,"sucess"));
			actions.addAction(new PanAction(giant,0.1));
			actions.addAction(new CallFunctionAction(removeDisguise));
			actions.addAction(new MoveAction(giant, new Point(3200,740)));
			actions.addAction(new TalkAction(giant,"sup"));
			actions.addAction(new TalkAction(vik1,"hey"));
			actions.addAction(new TalkAction(vik2,"wait"));
			actions.addAction(new PanAction(_player,0.1));
			actions.addAction(new TalkAction(_player,"uhoh"));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new PanAction(giant,0.1));
			actions.addAction(new TalkAction(giant,"catch"));
			actions.addAction(new AnimationAction(giant, Stomp));
			actions.addAction(new PanAction(_player,0.1));
			actions.addAction(new PanAction(_player));
			actions.addAction(new TalkAction(mya,"chute"));	
			actions.addAction(new MoveAction(mya, drain));
			actions.addAction(new CallFunctionAction(Command.create(parent.removeEntity,mya)));
			actions.addAction(new MoveAction(jorge, drain));
			actions.addAction(new CallFunctionAction(Command.create(parent.removeEntity,jorge)));
			actions.addAction(new MoveAction(oliver, drain));
			actions.addAction(new CallFunctionAction(Command.create(parent.removeEntity,oliver)));
			actions.addAction(new MoveAction(_player, drain));
			actions.addAction(new CallFunctionAction(Command.create(shellApi.loadScene,Fortress)));
			
			actions.execute();
			
			shellApi.completeEvent(_events.BALANCE_GAME_COMPLETE);
		}		
		
		private function removeDisguise():void
		{
			tiltWarningHandler(false);
			
			Display(mya.get(Display)).setContainer(_container);
			Display(jorge.get(Display)).setContainer(_container);
			Display(oliver.get(Display)).setContainer(_container);
			
			EntityUtils.position(mya, 400, 704);
			EntityUtils.position(oliver, 500, 704);
			EntityUtils.position(jorge, 700, 704);
			
			var charGroup:CharacterGroup = CharacterGroup( parent.getGroupById("characterGroup") );
			charGroup.addFSM(mya);
			charGroup.addFSM(oliver);
			charGroup.addFSM(jorge);
			
			Display(mya.get(Display)).visible = true;
			Display(jorge.get(Display)).visible = true;
			
			Motion(_player.get(Motion)).maxVelocity.x = 400;
			CharacterMotionControl(_player.get(CharacterMotionControl)).maxVelocityX = 400;
			Sleep( parent.getEntityById("giant2").get( Sleep )).ignoreOffscreenSleep = true;
			
			SkinUtils.hideSkinParts(_player, playerHiddenParts, false);
			
			for each(var en:Entity in segmentChain.get(BalanceSegmentComp).segments)
			{
				removeEntity(en);
			}
			segmentChain.remove(BalanceSegmentComp);
		}		
	}
}