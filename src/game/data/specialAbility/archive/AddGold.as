// Status: inactive
// Card 3093

package game.data.specialAbility.character 
{
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	
	import engine.components.Display;
	
	import fl.motion.ColorMatrix;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.BlowingLeaves;
	import game.particles.emitter.specialAbility.Example;
	import game.particles.emitter.specialAbility.ExternalAssetEmitter;
	import game.particles.emitter.specialAbility.Fire;
	
	public class AddGold extends SpecialAbility
	{
		private var bActive : Boolean = false;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			var colourFilter:ColorMatrix = new ColorMatrix();
			colourFilter.adjustBrightness(90);
			colourFilter.adjustContrast(-20);
			colourFilter.adjustSaturation(60);
			colourFilter.adjustHue(30);
			var colorF:ColorMatrixFilter = new ColorMatrixFilter(colourFilter);
			var glowF : GlowFilter = new GlowFilter(0xFFCC00, 5, 5, 5, 3, 3);
			node.entity.get(Display).displayObject.filters = [colorF, glowF];
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			node.entity.get(Display).displayObject.filters = [];
		}
		
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