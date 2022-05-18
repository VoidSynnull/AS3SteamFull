// Status: retired
// Usage ????

package game.data.specialAbility.character 
{
	import flash.display.MovieClip;
	import flash.utils.setTimeout;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.BlowingLeaves;
	import game.particles.emitter.specialAbility.Example;
	import game.particles.emitter.specialAbility.ExternalAssetEmitter;
	import game.particles.emitter.specialAbility.Fire;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class GumColors extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			var sPart : SkinPart = SkinUtils.getSkinPart( node.entity, SkinUtils.MOUTH);
			sCurMouthPart = sPart.value;
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "gum_colors" );
			setTimeout(listenForPop, 400);   // wait to load part... should make this load complete event driven
			bActive = true;
		}
		
		private function listenForPop(e):void{
			var mouthPartEntity : Entity = Skin(super.entity.get(Skin)).getSkinPartEntity(SkinUtils.MOUTH);
			var mouthPartMC : MovieClip = MovieClip(mouthPartEntity.get(Display).displayObject);
			var mouthPartAnimationMC : MovieClip = MovieClip(mouthPartMC.getChildAt(0));
			gumEntity = TimelineUtils.convertClip(mouthPartAnimationMC, super.group);
			timeline = gumEntity.get(Timeline);
			TimelineUtils.onLabel( gumEntity, "chewEnd", startPop, false );
		}
		
		private function startPop():void{
			if(bActive){
				if(Math.random() < 0.3){
					timeline.gotoAndPlay(aColors[Math.floor(aColors.length * Math.random())]+"Bubble");
					TimelineUtils.onLabel( gumEntity, "endPop", reChew );
				}else{  
					timeline.gotoAndPlay("chewStart");
				}
			}
		}
	
		private function reChew():void{
			timeline.gotoAndPlay("chewStart");
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			bActive = false;
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, sCurMouthPart );
		}
		
		private var timeline : Timeline;
		private var gumEntity:Entity;
		private var aColors : Array = ["pink", "blue", "yellow", "green", "purple"];
		private var sCurMouthPart : String = "";
		private var _emitterClass:Class;
		private var emitter:Object;
		private var xOffset:Number = 0;
		private var yOffset:Number = 0;
		private var followCharacter:Boolean = false;
		private var useCharacterPosition:Boolean = false;
		private var bActive : Boolean = false;
		private var sAssetPath : String = "";
		private var example:Example;
		private var fire:Fire;
		private var leaves:BlowingLeaves;
		private var externalEmitter:ExternalAssetEmitter;
		
	}

}