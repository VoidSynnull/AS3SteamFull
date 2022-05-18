// Status: retired
// Usage ????

package game.data.specialAbility.character 
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.setTimeout;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.BlowingLeaves;
	import game.particles.emitter.specialAbility.Example;
	import game.particles.emitter.specialAbility.ExternalAssetEmitter;
	import game.particles.emitter.specialAbility.ExternalBlast;
	import game.particles.emitter.specialAbility.Fire;
	import game.particles.emitter.specialAbility.FireBlast;
	import game.particles.emitter.specialAbility.FlameBlast;
	import game.particles.emitter.specialAbility.SmokeBlast;
	import game.particles.emitter.specialAbility.SnowBlast;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	public class AddBlast extends SpecialAbility
	{
		
		private var bActive : Boolean = false;
		
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			// Access the params
			var uEmitter : uint = 0;
			// change to use setPropsFromParams()
			while(super.data.getInitParam("emitterClass"+uEmitter)){
				aEmitters[uEmitter] = new Array();
				aEmitters[uEmitter]["emitterClass"] = ClassUtils.getClassByName(super.data.getInitParam("emitterClass"+uEmitter));
				aEmitters[uEmitter]["yOffset"] = aEmitters[uEmitter]["xOffset"] = 0;
				aEmitters[uEmitter]["particleAsset"] = "";
				aEmitters[uEmitter]["blastCount"] = 20; 
				if(super.data.getInitParam("xOffset"+uEmitter))
				{
					aEmitters[uEmitter]["xOffset"] = Number(super.data.getInitParam("xOffset"+uEmitter));
				}
				if(super.data.getInitParam("yOffset"+uEmitter))
				{
					aEmitters[uEmitter]["yOffset"] = Number(super.data.getInitParam("yOffset"+uEmitter));
				}
				if(super.data.getInitParam("followCharacter"+uEmitter))
				{
					aEmitters[uEmitter]["followCharacter"] = super.data.getInitParam("followCharacter"+uEmitter) == "true" ? true : false;
				}
				if(super.data.getInitParam("particleAsset"+uEmitter))
				{
					aEmitters[uEmitter]["particleAsset"] = super.data.getInitParam("particleAsset"+uEmitter);
				}
				if(super.data.getInitParam("blastCount"+uEmitter))
				{
					aEmitters[uEmitter]["blastCount"] = super.data.getInitParam("blastCount"+uEmitter);
				}
				uEmitter++;
			}
			
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if(!bActive)
			{
				// Create the emitter and init
				for(var u : uint = 0; u < aEmitters.length; u++){
					if(aEmitters[u]["particleAsset"] == ""){
						aEmitters[u]["emitter"] = new aEmitters[u]["emitterClass"]();
					}else{
						aEmitters[u]["emitter"] = new aEmitters[u]["emitterClass"](aEmitters[u]["particleAsset"], aEmitters[u]["blastCount"]);
					}
					aEmitters[u]["emitter"].init();
				
					if(useCharacterPosition)
					{
						xOffset = node.entity.get(Spatial).x + aEmitters[u]["xOffset"];
						yOffset = node.entity.get(Spatial).y + aEmitters[u]["yOffset"];
					}
				
					if(CharUtils[super.data.getInitParam("displayContainer")]){
						//var followTarget:Spatial = CharUtils.getPart( node.entity, CharUtils[super.data.getInitParam("displayContainer")] ).get(Spatial);
						//var container:DisplayObjectContainer = CharUtils.getPart( node.entity, CharUtils[super.data.getInitParam("displayContainer")] ).get(Display).container;
						
					}
					var container:DisplayObjectContainer = node.entity.get(Display).container;
					var followTarget:Spatial = node.entity.get(Spatial);
					
					EmitterCreator.create( group, container, aEmitters[u]["emitter"] as Emitter2D, aEmitters[u]["xOffset"], aEmitters[u]["yOffset"] , null, "", followTarget);
					setTimeout(stopSmoke, 1500);
				}
				bActive = true;
			}else{
				deactivate(node);
			}
			
		}
		
		private function stopSmoke():void{
			aEmitters[0]["emitter"].stopEmitter();  // assuming first emitter from XML is SmokeBlast
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			bActive = false;
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
		private var fB2:FireBlast = new FireBlast;
		private var fB:FlameBlast = new FlameBlast;
		private var sB:SmokeBlast = new SmokeBlast;
		private var sB2:SnowBlast = new SnowBlast;
		private var eB:ExternalBlast = new ExternalBlast("");
		private var aEmitters : Array = new Array();
		private var leaves:BlowingLeaves;
		private var externalEmitter:ExternalAssetEmitter;
		
	}

}