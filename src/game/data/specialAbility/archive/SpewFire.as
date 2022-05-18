// Status: retired
// Usage (1) ads
// Used by cards 2530

package game.data.specialAbility.character 
{
	import flash.display.DisplayObjectContainer;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.ShootFlames;
	import game.scene.template.CharacterGroup;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.twoD.emitters.Emitter2D;	
	
	public class SpewFire extends SpecialAbility
	{
		
		private var bActive : Boolean = false;
		
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			// change to use setPropsFromParams()
			// Access the params
			_emitterClass = ShootFlames;
			if(super.data.getInitParam("xOffset"))
			{
				xOffset = Number(super.data.getInitParam("xOffset"));
			}
			if(super.data.getInitParam("yOffset"))
			{
				yOffset = Number(super.data.getInitParam("yOffset"));
			}
			if(super.data.getInitParam("startColor"))
			{
				startColor = Number(super.data.getInitParam("startColor"));
			}
			if(super.data.getInitParam("endColor"))
			{
				endColor = Number(super.data.getInitParam("endColor"));
			}
			
			// Save the previous mouth part
			prevMouth = SkinUtils.getSkinPart( node.entity, SkinUtils.MOUTH).value;
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "ad_fire_mouth" );
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				super.setActive( true );
				SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "ooh" );
				//var fire:ShootFlames = new ShootFlames();
				//fire.addInitializer( new ChooseInitializer([new ImageClass(Blob, [3, startColor], true)]));
				dir = 1;
				// if facing left
				character = node.entity;
				var spatial:Spatial = character.get(Spatial);
				if (spatial.scaleX > 0)
					dir = -1;
				emitter = new _emitterClass();
				emitter.init(dir, startColor, endColor);
				emitter.addInitializer( new ChooseInitializer([new ImageClass(Blob, [3], true)]));
				var container:DisplayObjectContainer = node.entity.get(Display).container;
				var xOff:Number = xOffset;
				_emitterEntity = EmitterCreator.create( group, container, emitter as Emitter2D, xOffset*dir, yOffset , null, "", spatial);
				SceneUtil.addTimedEvent( super.group, new TimedEvent( 0.5, 1, removeLook));
			}
		}
		
		private function removeLook():void
		{
			SkinUtils.setSkinPart( super.entity, SkinUtils.MOUTH, "ad_fire_mouth" );
			var inSceneNpcs:Vector.<Entity> = (super.group.getGroupById('characterGroup') as CharacterGroup).getCharactersInView();
			var spatial:Spatial = character.get(Spatial);		
			if (inSceneNpcs)
			{
				for (var i:int = 0; i < inSceneNpcs.length; i++) 
				{
					if (dir * (inSceneNpcs[i].get(Spatial).x - spatial.x) > 0)
					{
						//var colourFilter:ColorMatrix = new ColorMatrix();
						//colourFilter.adjustBrightness(-100);
						var colorF:GlowFilter = new GlowFilter(0x00000000, 0.8, 100, 100, 1, 1, true);
						inSceneNpcs[i].get(Display).displayObject.filters = [colorF];
					}
				}
			}
			SceneUtil.lockInput( super.group, false );
			super.setActive( false );
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.group.removeEntity(_emitterEntity);
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, prevMouth );
		}
		
		private var prevMouth:String;
		private var _emitterEntity:Entity;
		private var _emitterClass:Class;
		private var emitter:Object;
		private var xOffset:Number = 0;
		private var yOffset:Number = 0;
		private var followCharacter:Boolean = true;
		private var useCharacterPosition:Boolean = false;
		private var startColor:Number = 0xFFFF6600;
		private var endColor:Number = 0x00CC0000;
		private var character:Entity;
		private var dir:int;
	}
}
