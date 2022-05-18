// Status: retired
// Usage (1) ads
// Used by cards 2685

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
	
	// for removing the ability (see init)
	import game.data.specialAbility.SpecialAbilityData;
	import game.components.specialAbility.SpecialAbilityControl;
	
	public class ProjectileBreath extends SpecialAbility
	{
		//private var bActive : Boolean = false;
		
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
						
			// DISABLING THIS ABILITY, DELETE THESE LINES TO RE-ENABLE
			var specialAbilityData:SpecialAbilityData = super.group.shellApi.player.get( SpecialAbilityControl ).getSpecialByClass(ProjectileBreath);
			super.shellApi.specialAbilityManager.removeSpecialAbility(super.group.shellApi.player, super.data.id);
			return;
			// DISABLING THIS ABILITY, DELETE THESE LINES TO RE-ENABLE
			
			_emitterClass = ShootFlames;
			
			// change to use setPropsFromParams()
			_xOffset = _yOffset = 0;
			if ( super.data.getInitParam("xOffset") )
				_xOffset = Number(super.data.getInitParam("xOffset"));
			
			if( super.data.getInitParam("yOffset") )
				_yOffset = Number(super.data.getInitParam("yOffset"));
			
			var nextColorIndex:int = 1;
			
			_startColors = new Array();
			_endColors = new Array();
			_charredColors = new Array();
			
			while ( super.data.getInitParam("startColor" + nextColorIndex) != null && super.data.getInitParam("endColor" + nextColorIndex) != null && super.data.getInitParam("charredColor" + nextColorIndex) != null )
			{
				_startColors.push(Number(super.data.getInitParam("startColor" + nextColorIndex)));
				_endColors.push(Number(super.data.getInitParam("endColor" + nextColorIndex)));
				_charredColors.push(Number(super.data.getInitParam("charredColor" + nextColorIndex)));
				nextColorIndex ++;
			}
			
			_currentColorIndex = 0;
			_totalColors = nextColorIndex - 1; // decrementing for the color that was not fetched
			
			_prevMouth = SkinUtils.getSkinPart( node.entity, SkinUtils.MOUTH).value;
			
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "ad_fire_mouth" );
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				// fix this; had to hard-code tracking call last-second
				super.shellApi.adManager.track("WingsOfFireIC", "TriggerSpaceBar", "Dragon Breath");
				
				super.setActive( true );
				
				SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "ooh" );
				
				_character = node.entity;
				
				var spatial:Spatial = _character.get(Spatial);
				if ( spatial.scaleX > 0 )
					_characterDir = -1;
				else
					_characterDir = 1;
				
				_emitter = new _emitterClass();
				_emitter.init(_characterDir, _startColors[_currentColorIndex], _endColors[_currentColorIndex]);
				_emitter.addInitializer( new ChooseInitializer([new ImageClass(Blob, [3], true)]));
				
				var emitterContainer:DisplayObjectContainer = node.entity.get(Display).container;
				
				_emitterEntity = EmitterCreator.create( super.group, emitterContainer, _emitter as Emitter2D, _xOffset*_characterDir, _yOffset , null, "", spatial);
				SceneUtil.addTimedEvent( super.group, new TimedEvent( 0.5, 1, removeLook));
			}
		}
		
		private function removeLook():void
		{
			SkinUtils.setSkinPart( super.entity, SkinUtils.MOUTH, "ad_fire_mouth" );
			
			var inSceneNpcs:Vector.<Entity> = (super.group.getGroupById('characterGroup') as CharacterGroup).getCharactersInView();
			var spatial:Spatial = _character.get(Spatial);		
			
			if ( inSceneNpcs )
			{
				for (var i:int = 0; i < inSceneNpcs.length; i++) 
				{
					if (_characterDir * (inSceneNpcs[i].get(Spatial).x - spatial.x) > 0)
					{
						var charredFilter:GlowFilter = new GlowFilter(_charredColors[_currentColorIndex], 0.8, 100, 100, 100, 1, true);
						inSceneNpcs[i].get(Display).displayObject.filters = [charredFilter];
					}
				}
			}
			
			_currentColorIndex ++; // increment now that all colors have been used
			// and check to see if we should cycle back to the first color
			if ( _currentColorIndex == _totalColors )
				_currentColorIndex = 0;
			
			SceneUtil.lockInput( super.group, false ); // was input ever locked?
			
			super.setActive( false );
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.group.removeEntity(_emitterEntity);
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, _prevMouth );
		}
		
		private var _emitterClass:Class;
		private var _xOffset:Number;
		private var _yOffset:Number;
		private var _startColors:Array;
		private var _endColors:Array;
		private var _charredColors:Array;
		
		private var _currentColorIndex:int;
		private var _totalColors:int;
		
		private var _prevMouth:String;
		private var _character:Entity;
		private var _characterDir:int;
		
		private var _emitterEntity:Entity;
		private var _emitter:Object;
	}
}
