package game.scene.template
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.hit.BitmapHitArea;
	import game.components.hit.Bounce;
	import game.components.hit.BounceWire;
	import game.components.hit.Ceiling;
	import game.components.hit.Climb;
	import game.components.hit.Hazard;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.hit.PlatformRebound;
	import game.components.hit.Radial;
	import game.components.hit.Wall;
	import game.components.hit.Water;
	import game.components.hit.Zone;
	import game.components.render.Reflective;
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.HitParser;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.systems.audio.HitAudioSystem;
	import game.systems.hit.BaseGroundHitSystem;
	import game.systems.hit.BitmapCollisionSystem;
	import game.systems.hit.BitmapPlatformCollisionSystem;
	import game.systems.hit.BounceHitSystem;
	import game.systems.hit.BounceWireSystem;
	import game.systems.hit.CeilingHitSystem;
	import game.systems.hit.ClimbHitSystem;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.HitEntityListSystem;
	import game.systems.hit.MoverHitSystem;
	import game.systems.hit.MovingHitSystem;
	import game.systems.hit.PlatformHitSystem;
	import game.systems.hit.PlatformReboundHitSystem;
	import game.systems.hit.RadialHitSystem;
	import game.systems.hit.ResetColliderFlagSystem;
	import game.systems.hit.WallHitSystem;
	import game.systems.hit.WaterHitSystem;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.render.ReflectionSystem;
	import game.util.BitmapUtils;
	import game.util.ColorUtil;
	import game.util.PerformanceUtils;

	public class CollisionGroup extends Group
	{
		public function CollisionGroup()
		{
			super();
			this.id = GROUP_ID;
		}
		
		override public function destroy():void
		{			
			if (this.hitBitmapData) this.hitBitmapData.dispose();
			this.hitBitmapData = null;
			_hitContainer = null;
			super.destroy();
		}
		
		/**
		 * For most scenes this is the only method you need to do setup.  Copies the appropriate container and asset/data prefixes, add the camera system and sets up layers.
		 * @param   [scene] : The Scene to pull layer data from and use for setup.  Defaults to the parent of this Group.
		 */
		public function setupScene(scene:Scene, xml:XML, hitContainer:DisplayObjectContainer, audioGroup:AudioGroup, showHits:Boolean = false):void
		{			
			_hitContainer = hitContainer;
			// add it as a child group to give it access to systemManager.
			scene.addChildGroup(this);
			_scene = scene;
			
			var hitTypes:Vector.<Class> = create(xml, audioGroup, showHits);
			addHitSystems(hitTypes, scene.sceneData.bounds.right, scene.sceneData.bounds.bottom, showHits);
			
			if(allHitData["baseGround"] != null)
			{
				var baseGroundHitSystem:BaseGroundHitSystem = super.parent.getSystem(BaseGroundHitSystem) as BaseGroundHitSystem;
				if(audioGroup)
				{
					var audioData:Dictionary = audioGroup.audioData;
					
					if(audioData)
					{
						audioData = audioData["baseGround"];
					}
					baseGroundHitSystem.setBaseGroundHitData(allHitData["baseGround"], audioData);
				}
			}
		}
		
		public function create(hitXml:XML, audioGroup:AudioGroup = null, showHits:Boolean = false):Vector.<Class>
		{
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.showHits = showHits;
			var hitParser:HitParser = new HitParser();
			var hitTypes:Vector.<Class> = new Vector.<Class>;
			var audioData:Dictionary;
			
			if(audioGroup != null)
			{
				audioData = audioGroup.audioData;
			}
			
			this.allHitData = new Dictionary();
			
			if (hitXml != null)
			{
				this.allHitData = hitParser.parse(hitXml);
				// create bitmap hits and add sound from data.
				hitTypes = hitCreator.addBitmapHitsFromData(this.allHitData, super.parent, audioData);
			}
			
			// Must scan the hit layer movieclip-based hit areas before characters are added to it.
			hitTypes = hitTypes.concat(hitCreator.addHitsFromContainer(_hitContainer, this.allHitData, super.parent, audioData));
			
			return(hitTypes);
		}
		
		public function createHitAreaEntity(hitArea:BitmapData, scale:Number, offsetX:Number, offsetY:Number):Entity
		{
			var entity:Entity = new Entity();
			
			entity.add(new BitmapHitArea(hitArea));
			entity.add(new Id(HITAREA_ENTITY_ID));
			
			var spatial:Spatial = new Spatial(offsetX, offsetY);
			spatial.scale = scale;
			entity.add(spatial);
			
			return(entity);
		}
		
		public function addHitSystems(hitTypes:Vector.<Class>, width:Number, height:Number, showHits:Boolean = false):void 
		{						
			super.parent.addSystem(new BoundsCheckSystem(), SystemPriorities.resolveCollisions);
			super.parent.addSystem(new BaseGroundHitSystem(), SystemPriorities.checkCollisions);
			super.parent.addSystem(new ResetColliderFlagSystem(), SystemPriorities.resetColliderFlags);
			super.parent.addSystem(new HitEntityListSystem(), SystemPriorities.checkCollisions);
			super.parent.addSystem(new HitAudioSystem(), SystemPriorities.updateSound);
			
			if(allHitData != null)
			{
				var bitmapPlatforms:Dictionary = new Dictionary();
				var bitmapHits:Dictionary = new Dictionary();
				var colors:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>();
				var bitmapHitsActive:Boolean = false;
				var bitmapPlatformHitsActive:Boolean = false;
				var wrapX:uint = 0; // RLH: for wrapping bitmap hits
				
				for each(var hitData:HitData in allHitData)
				{
					// check for a color property to determine the hitData corresponds to a bitmap hit area.
					if(hitData.color)
					{
						colors.push(ColorUtil.hexToRgb(hitData.color));
						
						if(hitData.platform)
						{
							bitmapPlatformHitsActive = true;
							bitmapPlatforms[hitData.color] = hitData;
							// RLH: to wrap bitmap hits (only one occurence will wrap all the bitmap hits)
							if (hitData.wrapX != 0)
							{
								wrapX = hitData.wrapX;
							}
						}
						else
						{
							bitmapHitsActive = true;
							bitmapHits[hitData.color] = hitData;
						}
					}
				}
				
				var bitmapContainer:MovieClip;
				// check if bitmap_hits layer exists
				var bitmapEntity:Entity = _scene.getEntityById("bitmap_hits");
				if (bitmapEntity != null) {
					bitmapContainer = bitmapEntity.get(Display).displayObject;
				} else if (_hitContainer.hasOwnProperty("bitmapHits")) {
					bitmapContainer = _hitContainer["bitmapHits"];
				}
				
				if(bitmapContainer != null && bitmapContainer.width != 0 && bitmapContainer.height != 0)
				{
					var bounds:Rectangle = bitmapContainer.getBounds(bitmapContainer);
					
					this.hitBitmapData = BitmapUtils.createBitmapData(bitmapContainer, this.hitBitmapDataScale);
					this.hitBitmapOffsetX = -bounds.left * this.hitBitmapDataScale;
					this.hitBitmapOffsetY = -bounds.top * this.hitBitmapDataScale;
					//ColorUtil.clampToColors(this.hitBitmapData, colors);
					
					// remove bitmapContainer after we've extracted the hits
					if (bitmapContainer.parent == _hitContainer)
					{
						_hitContainer.removeChild(bitmapContainer);
					}
				}
				else
				{
					// if existing bitmapContainer not found create an empty canvas that can be added to later.
					//   we probably don't need to do this, but keeping it in for the moment in case ads need it.
					this.hitBitmapData = new BitmapData(1, 1);
				}
				
				// Create an entity that will hold bitmap hit area properties for all hit systems that need it (BitmapCollision, BitmapPlatformCollision and RadialCollision.)
				var hitAreaEntity:Entity = createHitAreaEntity(this.hitBitmapData, this.hitBitmapDataScale, this.hitBitmapOffsetX, this.hitBitmapOffsetY);
				super.parent.addEntity(hitAreaEntity);
				
				if(bitmapPlatformHitsActive)
				{
					var bitmapPlatformHitSystem:BitmapPlatformCollisionSystem = new BitmapPlatformCollisionSystem(bitmapPlatforms, wrapX);
					super.parent.addSystem(bitmapPlatformHitSystem, SystemPriorities.resolveCollisions);
				}
				
				if(bitmapHitsActive)
				{
					var bitmapHitSystem:BitmapCollisionSystem = new BitmapCollisionSystem(bitmapHits, wrapX);
					super.parent.addSystem(bitmapHitSystem, SystemPriorities.resolveCollisions);
				}
				
				// enable display of hit areas for testing
				if(showHits && (bitmapPlatformHitsActive || bitmapHitsActive))
				{
					var hitBitmap:Bitmap = new Bitmap(this.hitBitmapData);
					hitBitmap.alpha = .3;
					_hitContainer.addChild(hitBitmap);
					hitBitmap.x = -this.hitBitmapOffsetX / this.hitBitmapDataScale;
					hitBitmap.y = -this.hitBitmapOffsetY / this.hitBitmapDataScale;
					hitBitmap.scaleX = 1 / this.hitBitmapDataScale;
					hitBitmap.scaleY = 1 / this.hitBitmapDataScale;

					
					if(bitmapPlatformHitsActive)
					{
						bitmapPlatformHitSystem.canvas = new Sprite();
						_hitContainer.addChild(bitmapPlatformHitSystem.canvas);
					}
					
					if(bitmapHitsActive)
					{
						bitmapHitSystem.canvas = new Sprite();
						_hitContainer.addChild(bitmapHitSystem.canvas);
					}
				}
			}

			// add special platform types.
			var total:Number = hitTypes.length;
			var hit:Class;
			
			for (var n:Number = total - 1; n >= 0; n--)
			{
				hit = hitTypes[n];
				
				switch(hit)
				{
					case Platform :
						super.parent.addSystem(new PlatformHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case PlatformRebound :
						super.parent.addSystem(new PlatformReboundHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Wall :
						super.parent.addSystem(new WallHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Ceiling :
						super.parent.addSystem(new CeilingHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Motion :
						super.parent.addSystem(new MovingHitSystem(), SystemPriorities.move);
						break;
					
					case Bounce :
						super.parent.addSystem(new BounceHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Climb :
						super.parent.addSystem(new ClimbHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Mover :
						super.parent.addSystem(new MoverHitSystem(), SystemPriorities.resolveParentCollisions);
						break;
					
					case Hazard :
						super.parent.addSystem(new HazardHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Water :
						super.parent.addSystem(new WaterHitSystem(), SystemPriorities.moveComplete);
						super.parent.addSystem(new ParticleSystem(), SystemPriorities.update);
						break;
					
					case Zone :
						super.parent.addSystem(new ZoneHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Radial :
						var bitmapRadialCollisionSystem:RadialHitSystem = new RadialHitSystem();
						bitmapRadialCollisionSystem.colors = colors;
						super.parent.addSystem(bitmapRadialCollisionSystem, SystemPriorities.checkCollisions);
						
						if(showHits)
						{
							bitmapRadialCollisionSystem.canvas = new Sprite();
							_hitContainer.addChild(bitmapRadialCollisionSystem.canvas);
						}
						break;
					
					case BounceWire :
						super.parent.addSystem(new BounceWireSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case Reflective :
						if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
						{
							super.parent.addSystem(new ReflectionSystem());
						}
						break;
				}
			}
		}
		
		private var _scene:Scene;
		public var allHitData:Dictionary;
		public var hitBitmapData:BitmapData;
		public var hitBitmapDataScale:Number = .5;
		public var hitBitmapOffsetX:Number = 0;
		public var hitBitmapOffsetY:Number = 0;
		private var _hitContainer:DisplayObjectContainer;
		public static const GROUP_ID:String = "collisionGroup";
		public static const HITAREA_ENTITY_ID:String = "bitmapHitArea";
	}
}