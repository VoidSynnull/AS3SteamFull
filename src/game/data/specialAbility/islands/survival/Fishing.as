// Used by:
// Card "fishing_pole" on survival5 island (baseCamp scene) using item fishing_pole_test

package game.data.specialAbility.islands.survival
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.entity.Parent;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	import game.components.motion.Edge;
	import game.components.timeline.Timeline;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.survival2.shared.components.Hook;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	/**
	 * Cast fishing line with hook and reel in 
	 */
	public class Fishing extends SpecialAbility
	{
		private var DEFAULT_LINE_LENGTH:Number = 20;
		public static const CAST_LINE:String = "cast_line";
		public static const FISHING_HOOK:String = "fishingHook";
		
		private var _scene:PlatformerGameScene;
		
		public function get scene():PlatformerGameScene{return _scene;}
		public function get hook():Entity{return _hook;}
		public function get partDisplay():MovieClip{return _partDisplay;}
		
		private var _hook:Entity;
		private var _hookComponent:Hook;
		private var _hookClip:MovieClip;
		private var _partDisplay:MovieClip;
		
		public var _defaultLineLength:Number = DEFAULT_LINE_LENGTH;
		
		public var bait:String = "none";
		
		override public function init(node:SpecialAbilityNode):void
		{
			// need this if we want to load assets
			super.init(node);
			
			_scene = super.group as PlatformerGameScene;
			// if the special ability used outside of a platformer game scene 
			// which this special ability really requires, then remove it
			if(_scene == null)
			{
				CharUtils.removeSpecialAbility(node.entity, data);
				return;
			}
			
			_partDisplay = CharUtils.getPart( node.entity, CharUtils.ITEM).get(Display).displayObject;
			_partDisplay.noLine.visible = false;
			_partDisplay.hasLine.visible = true;
			
			// load hook 
			super.loadAsset("specialAbility/objects/hook.swf", this.hookLoaded);
		}

		override public function activate(node:SpecialAbilityNode):void
		{
			var partDisplay:MovieClip = CharUtils.getPart( node.entity, CharUtils.ITEM).get(Display).displayObject;

			if(!this.data.isActive)	// if activate is called and not yet active create Hook Entity and 
			{
				// only create hook if character is in valid state
				var state:String = CharUtils.getStateType(node.entity);
				if(state == CharacterState.STAND || state == CharacterState.WALK || state == CharacterState.RUN ||
					state == CharacterState.SKID || state == CharacterState.DUCK || state == CharacterState.IDLE)
				{
					// create hook entity
					_hook = EntityUtils.createSpatialEntity(this._scene, this._hookClip, this._scene.hitContainer);
					_hook.add(new Id(FISHING_HOOK));
					_hookComponent = new Hook( this._scene.hitContainer, _defaultLineLength, bait);
					_hook.add( _hookComponent );
					_hook.add(new ZoneCollider());
					_hook.add(new BitmapCollider());
					_hook.add(new CurrentHit());
					_hook.add(new PlatformCollider());
					_hook.add(new Edge(-10, -10, 20, 20));
					_hook.add(new MotionBounds(this._scene.sceneData.cameraLimits));
					_hook.add(new Parent( node.entity ) );
					
					var validHits:ValidHit = new ValidHit();
					validHits.inverse = true;
					_hook.add(validHits);
					
					var motion:Motion 		= new Motion();
					motion.friction 		= new Point(150, 0);
					motion.acceleration.y 	= 400;
					_hook.add(motion);
					
					TimelineUtils.convertClip(this._hookClip, super.group, _hook, null, false);
					_hook.get(Timeline).gotoAndStop(bait);
					
					// determine hook start from pole asset
					var lineStartClip:MovieClip = partDisplay.lineStart;
					_hookComponent.poleRotation = GeomUtils.radiansBetween( 0, 0, lineStartClip.x, lineStartClip.y );
					_hookComponent.poleDistance = GeomUtils.dist( 0, 0, lineStartClip.x, lineStartClip.y ) * Spatial(node.entity.get(Spatial)).scale;
					
					// set camera to follow hook
					SceneUtil.setCameraTarget(_scene, _hook);
					
					// hide hook & line (will get unhidden when positioned );
					EntityUtils.visible( _hook, false );
					_hookComponent.line.visible = false;

					this.setActive(true);
					
					super.shellApi.triggerEvent(CAST_LINE);
				}
			}
			else
			{
				// if activate is called again, while active then reel in line
				if( _hookComponent.state == _hookComponent.REELING_STATE )
				{
					_hookComponent.state = _hookComponent.FALLING_STATE;
				}
				else
				{
					_hookComponent.state = _hookComponent.REELING_STATE;
				}
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			if(_scene)
			{
				if(this._hook)
				{
					this._scene.removeEntity(this._hook, true);
					_hook = null;
					//_hookClip = null;
					_hookComponent = null;
				}
				
				SceneUtil.setCameraTarget(_scene, _scene.player);	// return camera to player
			}
			
			super.deactivate(node);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{	
			//Player motion, if player moves remove hook and line
			var motion:Motion = node.entity.get(Motion);
			if(Math.abs(motion.velocity.x) > 20 || Math.abs(motion.velocity.y) > 20 || _hookComponent.remove )
			{
				this.setActive(false);
				deactivate(node);
			}
		}

		private function hookLoaded(clip:MovieClip):void
		{
			this._hookClip = clip;
		}
	}
}