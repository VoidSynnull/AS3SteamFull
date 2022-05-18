// Status: retired
// Card 3050

package game.data.specialAbility.character 
{
	import flash.display.DisplayObjectContainer;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import fl.motion.ColorMatrix;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.BlowingLeaves;
	import game.particles.emitter.specialAbility.Example;
	import game.particles.emitter.specialAbility.ExternalAssetEmitter;
	import game.particles.emitter.specialAbility.Fire;
	import game.util.ClassUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	public class AddFlames extends SpecialAbility
	{
		
		private var bActive : Boolean = false;
		
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			// change to use setPropsFromParams()
			// Access the params
			if(super.data.getInitParam("xOffset"))
			{
				xOffset = Number(super.data.getInitParam("xOffset"));
			}
			if(super.data.getInitParam("yOffset"))
			{
				yOffset = Number(super.data.getInitParam("yOffset"));
			}
			if(super.data.getInitParam("followCharacter"))
			{
				followCharacter = super.data.getInitParam("followCharacter") == "true" ? true : false;
			}
			
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			emitter = new _emitterClass();
			emitter.init();
			var colourFilter:ColorMatrix = new ColorMatrix();
			colourFilter.adjustBrightness(60);
			colourFilter.adjustContrast(-10);
			colourFilter.adjustSaturation(-10);
			colourFilter.adjustHue(35);
			var colorF:ColorMatrixFilter = new ColorMatrixFilter(colourFilter);
			var glowF : GlowFilter = new GlowFilter(0xFF9900, 5, 5, 5, 3, 3);
			node.entity.get(Display).displayObject.filters = [colorF, glowF];
			if(useCharacterPosition)
			{
				xOffset = node.entity.get(Spatial).x + xOffset;
				yOffset = node.entity.get(Spatial).y + yOffset;
			}
			var container:DisplayObjectContainer = node.entity.get(Display).container;
			var followTarget:Spatial = node.entity.get(Spatial);
			_emitterEntity = EmitterCreator.create( group, container, emitter as Emitter2D, xOffset, yOffset , null, "", followTarget);	
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.group.removeEntity(_emitterEntity);
		}
		
		private var _emitterEntity:Entity;
		private var _emitterClass:Class;
		private var emitter:Object;
		private var xOffset:Number = 0;
		private var yOffset:Number = 0;
		private var followCharacter:Boolean = false;
		private var useCharacterPosition:Boolean = false;
		private var sAssetPath : String = "";
		private var example:Example;
		private var fire:Fire;
		private var leaves:BlowingLeaves;
		private var externalEmitter:ExternalAssetEmitter;
		
	}
}