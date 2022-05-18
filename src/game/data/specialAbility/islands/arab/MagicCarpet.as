// Used by:
// Card "magic_carpet" on arab3 island

package game.data.specialAbility.islands.arab
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.collider.ClimbCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.motion.AccelerateToTargetRotation;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.scene.Vehicle;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.StandNinja;
	import game.data.scene.SceneType;
	import game.data.specialAbility.SpecialAbility;
	import game.data.ui.ToolTipType;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.arab3.shared.CarpetState;
	import game.scenes.arab3.shared.CarpetStateNode;
	import game.systems.SystemPriorities;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.VehicleMotionSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.counters.ZeroCounter;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	/**
	 * AAvatar stands on magic carpet
	 */
	public class MagicCarpet extends SpecialAbility
	{
		private var _componentClasses:Array = [WallCollider, PlatformCollider, ClimbCollider, HazardCollider, WaterCollider, CharacterMovement, CharacterMotionControl, Motion];
		private var _componentInstances:Array = [];
		private var _carpet:Entity;
		private var _particles:Entity;
		public var _assetPath:String;
		private var _clip:MovieClip;
		public var _xFlipOffset:Number = 0;
		public var _particleColor1:uint = 0x0; // black;
		public var _particleColor2:uint = 0x0; // black
		public var _noCarpet:Boolean = false;
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init( node );
			super.group.shellApi.logWWW("MagicCarpet :: init");
			suppressed = false;
			if(super.group is Scene)
			{
				// supress
				super.group.shellApi.logWWW("MagicCarpet :: init - isScene = true");
				if ( (Scene(super.group).sceneData.sceneType == SceneType.CUTSCENE) || (Scene(super.group).sceneData.suppressAbility) )
				{
					super.suppressed = true;
					super.group.shellApi.logWWW("MagicCarpet :: init - suppressed = true");
				}
				activate(node);
			}
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			//For some reason, this isn't being called appropriately elsewhere.
			//if(!this.data.isValidIsland(super.shellApi.island))return;
			
			if(!this.data.isActive && !suppressed)
			{
				super.group.shellApi.logWWW("MagicCarpet :: activate");
				this.setActive(true);
				
				CharUtils.setAnim(super.entity, StandNinja);
				CharUtils.stateDrivenOff(node.entity);
				
				DisplayUtils.moveToTop(Display(node.entity.get(Display)).displayObject);
				
				super.group.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);
				super.group.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
				super.group.addSystem(new VehicleMotionSystem(), SystemPriorities.moveComplete);
				
				if(_assetPath != null)
					super.group.shellApi.loadFileWithServerFallback("assets/"+_assetPath, onCarpetLoaded);
				else if(!_noCarpet)
					super.loadAsset("scenes/arab3/shared/carpet.swf", onCarpetLoaded);
				
				MotionUtils.zeroMotion(node.entity);
				if( node.entity.has( CharacterMotionControl ))
				{
					CharacterMotionControl(node.entity.get(CharacterMotionControl)).spinEnd = true;
				}
				Motion(node.entity.get(Motion)).rotation = 0;
				Spatial(node.entity.get(Spatial)).rotation = 0;
				
				for(var index:int = this._componentClasses.length - 1; index > -1; --index)
				{
					this._componentInstances.push(node.entity.remove(this._componentClasses[index]));
				}
				
				var motion:Motion 			= new Motion();
				motion.maxVelocity 			= new Point(500, 500);
				motion.friction 			= new Point(300, 300);
				node.entity.add(motion);
				
				var motionControlBase:MotionControlBase 			= new MotionControlBase();
				motionControlBase.acceleration 						= 800;
				motionControlBase.stoppingFriction 					= 600;
				motionControlBase.accelerationFriction 				= 0;
				motionControlBase.freeMovement 						= true;
				motionControlBase.rotationDeterminesAcceleration 	= false;
				motionControlBase.moveFactor 						= 0.3;
				node.entity.add(motionControlBase);
				
				node.entity.add(new Vehicle());
				node.entity.add(new AccelerateToTargetRotation(0));
				
				var fsmCreator:FSMStateCreator = new FSMStateCreator();
				fsmCreator.createState(node.entity, CarpetState, CarpetStateNode);
				
				
				if(node.entity.get(FSMControl) == null)
					node.entity.add(new FSMControl(super.shellApi));
				var fsmControl:FSMControl = node.entity.get(FSMControl);
				fsmControl.setState("carpet");
				
				SceneUtil.addTimedEvent(super.group, new TimedEvent(0.25, 1, setCursorToTarget));
			}
		}
		
		private function onCarpetLoaded(clip:MovieClip):void
		{
			if(clip)
			{
				super.group.shellApi.logWWW("MagicCarpet :: onCarpetLoaded");
				clip.y = 105;
				clip.scaleX = 1.7;
				clip.scaleY = 1.7;
				_clip = clip;
				
				var displayObject:DisplayObjectContainer = Display(super.entity.get(Display)).displayObject;
				
				this._carpet = EntityUtils.createSpatialEntity(super.group, displayObject.addChild(clip), null, true);
				//TimelineUtils.convertClip(clip, super.group, this._carpet);
				
				var bounds:Rectangle = clip.getBounds(displayObject.parent);
				
				if(_particleColor1 != 0x0)
				{
					var emitter:Emitter2D = new Emitter2D();
					emitter.counter = new Steady(40);
					emitter.addInitializer(new ImageClass(Dot, [2], true, 70));
					emitter.addInitializer(new Position(new RectangleZone(-bounds.width/2, -2, bounds.width/2, 2)));
					emitter.addInitializer(new Lifetime(1.2));
					emitter.addInitializer(new ScaleImageInit(0.5, 1));
					emitter.addAction(new ColorChange(_particleColor1, _particleColor2));
					emitter.addAction(new RandomDrift(50, 50));
					emitter.addAction(new Move());
					emitter.addAction(new Age());
					
					this._particles = EmitterCreator.create(super.group, displayObject.parent, emitter, 0, 37, null, null, super.entity.get(Spatial));
				}
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void 
		{
			if(this.data.isActive)
			{
				super.group.shellApi.logWWW("MagicCarpet :: deactivate");
				this.setActive(false);
				
				if(this._carpet)
				{
					super.group.removeEntity(this._carpet);
					this._carpet = null;
				}
				
				if(this._particles)
				{
					super.group.removeEntity(this._particles);
					this._particles = null;
				}
				
				node.entity.remove(MotionControlBase);
				
				for(var index:int = this._componentClasses.length - 1; index > -1; --index)
				{
					if(this._componentInstances[index] != null)
						node.entity.add(this._componentInstances[index]);
				}
				this._componentInstances.length = 0;
				
				MotionUtils.zeroMotion(node.entity);
				
				CharUtils.stateDrivenOn(node.entity);
				
				var fsmControl:FSMControl = node.entity.get(FSMControl);
				fsmControl.setState("fall");
				
				SceneUtil.addTimedEvent(super.group, new TimedEvent(0.25, 1, setCursorToArrow));
			}
		}
		
		private function setCursorToArrow():void
		{
			super.group.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		private function setCursorToTarget():void
		{
			super.group.shellApi.defaultCursor = ToolTipType.TARGET;
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			var motionControl:MotionControl = node.entity.get(MotionControl);
			if(motionControl.moveToTarget)
			{
				var motionTarget:MotionTarget = node.entity.get(MotionTarget);
				CharUtils.setDirection(node.entity, motionTarget.targetX > Spatial(node.entity.get(Spatial)).x);
			}
			if(_clip != null) {
				if(_clip.getChildByName("flipClip") != null) {
					if(node.entity.get(Spatial).scaleX < 0) {
						_clip.getChildByName("flipClip").scaleX = -1;
						_clip.getChildByName("flipClip").x = _xFlipOffset;
						
					}
					if(node.entity.get(Spatial).scaleX > 0) {
						_clip.getChildByName("flipClip").scaleX = 1;
						_clip.getChildByName("flipClip").x = 0;
						
					}
				}
			}
		}
		
		public function removeParticles():void
		{
			var emitter2D:Emitter2D = _particles.get( Emitter ).emitter2D;
			emitter2D.counter = new ZeroCounter();
		}
	}
}