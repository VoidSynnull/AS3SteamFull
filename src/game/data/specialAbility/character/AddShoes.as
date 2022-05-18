// Used by:
// Card 3496,3497,3498,3499 using avatar ability shoes_running_sneakers_(color)

package game.data.specialAbility.character
{
	import com.poptropica.AppConfig;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.Skin;
	import game.components.render.Line;
	import game.components.specialAbility.character.MotionBlur;
	import game.creators.entity.SkinCreator;
	import game.data.character.part.ColorAspectData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.specialAbility.character.MotionBlurSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	/**
	 * Add running shoes with motion blur 
	 */
	public class AddShoes extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(_shoePath == null || _shoePath == "")
			{
				// use a default shoe path if one was not given
				_shoePath = "specialAbility/objects/shoes/sneaker.swf"
			}
			trace("AddShoes path: " + _shoePath);
			
			this.loadAsset(_shoePath, loadComplete);
			
			if(_showBlur)
			{
				if(AppConfig.mobile)
				{
					_blursPerSecond *= .5;
					_lifeTime *= 2;
					_quality *= .5;
				}
				
				var blur:MotionBlur = new MotionBlur(_lifeTime, _blursPerSecond, _quality, _color, _alpha);
				super.entity.add(blur);
				
				if(!group.getSystem(MotionBlurSystem))
				{
					group.addSystem(new MotionBlurSystem());
				}
			}
		}
		
		private function loadComplete(shoeClip:MovieClip):void
		{
			if(!shoeClip || !entity.has(Skin)) return;
			trace("AddShoes got shoe clip for " + entity.get(Id).id);
			_shoeClip = shoeClip;
			SceneUtil.delay(entity.group, _delay, applyShoe);
		}

		private function applyShoe():void
		{
			_shoeClip.x = 0;
			_shoeClip.y = 0;
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(_shoeClip);
			var foot1ShoeSprite:Sprite = BitmapUtils.createBitmapSprite(_shoeClip, 1, null, true, 0, bitmapData);
			var foot2ShoeSprite:Sprite = BitmapUtils.createBitmapSprite(_shoeClip, 1, null, true, 0, bitmapData);
			
			var footList:Array = [SkinUtils.FOOT1, SkinUtils.FOOT2];
			for each (var foot:String in footList)
			{
				var footEntity:Entity = SkinUtils.getSkinPartEntity(entity, foot);
				if (footEntity != null)
				{
					var footDisplay:Display = footEntity.get(Display);
					if (footDisplay != null)
					{
						if (foot == SkinUtils.FOOT1)
						{
							_foot1Shoe = EntityUtils.createSpatialEntity(entity.group, foot1ShoeSprite, footDisplay.displayObject);
							_foot1Shoe.get(Display).visible = true;
							trace("AddShoes foot1: " + _foot1Shoe);
						}
						else
						{
							_foot2Shoe = EntityUtils.createSpatialEntity(entity.group, foot2ShoeSprite, footDisplay.displayObject);
							_foot2Shoe.get(Display).visible = true;
							trace("AddShoes foot2: " + _foot2Shoe);
						}
					}
					else
					{
						trace("AddShoes no skin display found for " + foot);
					}
				}
				else
				{
					trace("AddShoes no skin part found for " + foot);
				}
			}
			
			// save skin color so we can restore later
			var skinEntity:Entity = SkinUtils.getSkinPartEntity( entity, SkinUtils.SKIN_COLOR );
			var colorSet:ColorSet = skinEntity.get( ColorSet );
			var aspect:ColorAspectData = colorSet.getColorAspectLast();
			_origSkinColor = aspect.value;

			// line stuff
			drawLines(true, _skinColor, _lineThickness, _darken);
			
			this.setActive(true);
		}
		
		private function drawLines(activate:Boolean, skinColor:Number = -1, lineThickness:Number = -1, darken:Number = -1):void
		{
			var limbList:Array = [CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK];
			
			// if restoring, then set restore/default values
			if (!activate)
			{
				skinColor = _origSkinColor;
				lineThickness = 0;
				darken = SkinCreator.DARKEN_SKIN;
			}
			
			for each (var part:String in limbList)
			{
				// set color or darken
				if ((skinColor != -1) || (darken != -1))
				{
					// get part entity and set darken percent to 0
					var partEnt:Entity = SkinUtils.getSkinPartEntity(entity, part);
					if (partEnt != null)
					{
						var colorSet:ColorSet = partEnt.get(ColorSet);
						if (colorSet != null)
						{
							// if coloring
							if (skinColor != -1)
							{
								var aspect:ColorAspectData = colorSet.getColorAspectLast();
								aspect.value = skinColor;
							}
							// if darkening
							if (darken != -1)
							{
								colorSet.darkenPercent = darken;
							}
							colorSet.invalidate = true;
						}
					}
				}
				
				// set line thickness
				if (lineThickness != -1)
				{
					partEnt = CharUtils.getPart( entity, part );
					if (partEnt != null)
					{
						var line:Line = partEnt.get(Line);
						if (line != null)
							line.lineWidth = lineThickness;
					}
				}
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			// line stuff
			drawLines(false);
			this.entity.remove(MotionBlur);
			this.entity.group.removeEntity(_foot1Shoe);
			this.entity.group.removeEntity(_foot2Shoe);
			super.deactivate(node);
		}
		
		// from xml
		public var _shoePath:String = "";
		public var _delay:Number = 0.2;
		public var _showBlur:Boolean = false;		
		public var _lifeTime:Number = .5;
		public var _blursPerSecond:Number = 10;
		public var _quality:Number = 1;
		public var _color:Number = NaN;
		public var _alpha:Number = 1;
		public var _skinColor:Number = -1;
		public var _lineThickness:Number = -1;
		public var _darken:Number = -1;
		
		private var _shoeClip:MovieClip;
		private var _foot1Shoe:Entity;
		private var _foot2Shoe:Entity;
		private var _origSkinColor:Number;
	}
}