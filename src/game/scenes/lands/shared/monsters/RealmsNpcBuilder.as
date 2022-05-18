package game.scenes.lands.shared.monsters {

	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.util.Command;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.scene.SceneInteraction;
	import game.data.character.CharacterData;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.util.SkinUtils;

	public class RealmsNpcBuilder {

		private var curScene:PlatformerGameScene;
		private var charGroup:CharacterGroup;

		public function RealmsNpcBuilder( scene:PlatformerGameScene ) {

			this.curScene = scene;
			this.charGroup = this.curScene.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;

		} //

		/**
		 * create master builder npc
		 * @param onLoaded( masterEntity ), called with params [ Entity ]
		 * @return 
		 */
		public function loadMasterBuilder( onLoaded:Function ):Entity {

			var charData:CharacterData = new CharacterData();
			charData.init( "masterBuilder", null, this.getMasterBuilderlook(), "left" );
			charData.ignoreDepth = true;

			var charGroup:CharacterGroup = this.curScene.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			// no way to get the entity to the callback...
			var entity:Entity = charGroup.createNpcFromData( charData, Command.create( this.masterBuilderLoaded, onLoaded ) );

			return entity;

		} //

		private function masterBuilderLoaded( e:Entity, onLoaded:Function=null ):void {

			if ( onLoaded ) {
				onLoaded( e );
			}

		} //

		private function singleNpcLoaded():void {

			var e:Entity;
			var monster:LandMonster;
			var life:Life;
			var motionControl:CharacterMotionControl;

			// doesn't use default interactions currently?
			e.remove( SceneInteraction );
			e.remove( Interaction );

			this.charGroup.addFSM( e );

		} //

		private function getMasterBuilderlook():LookData {

			var look:LookData = new LookData();

			look.id = "masterBuilder";

			look.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, 0xfbdfcb ) );
			look.applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, 0xf08b2c ) );
			look.applyAspect( new LookAspectData( SkinUtils.MOUTH, "astroGuard1" ) );
			look.applyAspect( new LookAspectData( SkinUtils.MARKS, "lands_builder" ) );
			look.applyAspect( new LookAspectData( SkinUtils.FACIAL, "lands_builder" ) );
			look.applyAspect( new LookAspectData( SkinUtils.HAIR, "lands_builder" ) );
			look.applyAspect( new LookAspectData( SkinUtils.SHIRT, "lands_builder" ) );
			look.applyAspect( new LookAspectData( SkinUtils.PANTS, "biker" ) );
			look.applyAspect( new LookAspectData( SkinUtils.PACK, "blueknight" ) );
			look.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, "squint" ) );

			return look;

		} //

	} // class

} // package