package game.scenes.myth.shared.abilities
{	
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Salute;
	import game.data.character.LookData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.AudioGroup;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;


	public class Electrify extends SpecialAbility
	{
		public function Electrify():void
		{
			
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			group = node.owning.group;
			var entity:Entity = node.entity;
			var sequence:Vector.<Class> = new Vector.<Class>;
			
			if( !group.shellApi.checkEvent( "zeus_appears_throne" ))
			{
				group.shellApi.triggerEvent( "cannot_use_poseidon" );
			}
			else
			{
				var motion:Motion = group.shellApi.player.get( Motion );
				
				if( motion.velocity.x == 0 && motion.velocity.y == 0 )
				{
					MotionUtils.zeroMotion( node.entity );
					SceneUtil.lockInput( node.owning.group );
					
					CharUtils.setAnim( node.entity, Salute );
					
					if ( !super.data.isActive )
					{
						super.setActive( true );
						CharUtils.getTimeline( entity ).handleLabel("raised", Command.create( setLook, node ));	
					}
					else
					{
						CharUtils.getTimeline( entity ).handleLabel("raised", Command.create( removeLook, node ));
					}
					CharUtils.getTimeline( entity ).handleLabel( "ending", Command.create( unlock, node ));
				}
			}
		}
		
		private function setLook( node:SpecialAbilityNode ):void
		{
			var entity:Entity = node.entity;
			var lookData:LookData = new LookData();
			var display:Display = entity.get( Display );

			var electrify:ElectrifyComponent = new ElectrifyComponent();
			var sprite:Sprite;
			var startX:Number;
			var startY:Number;
			
			if(!PlatformUtils.isMobileOS)
			{
				var colorFill:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 100, 100, 1, 1, true );
				var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
				var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true );
			
				var filters:Array = new Array( colorFill, whiteOutline, colorGlow );
				display.displayObject.filters = filters;
			}
			
			// Add her slight up/down bobbing
			var waveMotion:WaveMotion = new WaveMotion();
			var waveMotionData:WaveMotionData = new WaveMotionData( "y", 10, .02 );
			waveMotion.add( waveMotionData );
			
			// Electrify athena
			for( var number:int = 0; number < 10; number ++ )
			{
				sprite = new Sprite();
				startX = Math.random() * 120 - 60;
				startY = Math.random() * 280 - 140;
				
				sprite.graphics.lineStyle( 1, 0xFFFFFF );
				sprite.graphics.moveTo( startX, startY );
				
				electrify.sparks.push( sprite );
				electrify.lastX.push( startX );
				electrify.lastY.push( startY );
				electrify.childNum.push( display.displayObject.numChildren );
				
				display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
			}
			
			entity.add( electrify );
			var audioGroup:AudioGroup = node.owning.group.getGroupById( "audioGroup" ) as AudioGroup;
			
			audioGroup.addAudioToEntity( entity );
			
			group.shellApi.triggerEvent( "electrify_player" ); 
			group.addSystem( new ElectrifySystem());
		}
		
		private function unlock( node:SpecialAbilityNode ):void
		{
			var entity:Entity = node.entity;
			SceneUtil.lockInput( node.owning.group, false );
		}
		
		private function removeLook( node:SpecialAbilityNode ):void
		{
			var entity:Entity = node.entity
			var display:Display = entity.get( Display );
			display.displayObject.filters = new Array();
			
			for( var number:int = 0; number < 10; number ++ )
			{
				display.displayObject.removeChildAt( display.displayObject.numChildren - 1 );
			}
			
			entity.remove( ElectrifyComponent );
			group.shellApi.triggerEvent( "delectrify_player" );
			super.setActive( false );
		}
		
		private var group:Group;
	}
}