package game.scenes.examples
{
	import game.data.island.IslandEvents;
	import game.scenes.examples.animationSequencing.AnimationSequencing;
	import game.scenes.examples.audioExample.AudioExample;
	import game.scenes.examples.basicDialog.BasicDialog;
	import game.scenes.examples.basicPopup.BasicPopup;
	import game.scenes.examples.boatSceneExample.BoatSceneExample;
	import game.scenes.examples.bounceMaster.BounceMaster;
	import game.scenes.examples.cameraControl.CameraControl;
	import game.scenes.examples.cardChecker.CardChecker;
	import game.scenes.examples.characterAnimation.CharacterAnimation;
	import game.scenes.examples.characterNavigation.CharacterNavigation;
	import game.scenes.examples.characterParts.CharacterParts;
	import game.scenes.examples.characterPopup.CharacterPopup;
	import game.scenes.examples.complexDialog.ComplexDialog;
	import game.scenes.examples.customCharacter.CustomCharacter;
	import game.scenes.examples.cutSceneTest.CutSceneTest;
	import game.scenes.examples.debugExample.DebugExample;
	import game.scenes.examples.dynamicBoatScene.DynamicBoatScene;
	import game.scenes.examples.entitySleep.EntitySleep;
	import game.scenes.examples.fixedTimestepDemo.FixedTimestepDemo;
	import game.scenes.examples.gestureExample.GestureExample;
	import game.scenes.examples.hitAreas.HitAreas;
	import game.scenes.examples.inputExample.InputExample;
	import game.scenes.examples.itemExample.ItemExample;
	import game.scenes.examples.movingHitAreas.MovingHitAreas;
	import game.scenes.examples.multiplayerExample.MultiplayerExample;
	import game.scenes.examples.napeBasic.NapeBasic;
	import game.scenes.examples.napeCharacter.NapeCharacter;
	import game.scenes.examples.napeDynamicPlatforms.NapeDynamicPlatforms;
	import game.scenes.examples.napeMagnets.NapeMagnets;
	import game.scenes.examples.particlesExample.ParticlesExample;
	import game.scenes.examples.photoEvents.PhotoEvents;
	import game.scenes.examples.projectiles.Projectiles;
	import game.scenes.examples.sceneItems.SceneItems;
	import game.scenes.examples.scenePhysics.ScenePhysics;
	import game.scenes.examples.smartFoxHelloWorld.SmartFoxHelloWorld;
	import game.scenes.examples.specialAbilityExample.SpecialAbilityExample;
	import game.scenes.examples.standaloneAudio.StandaloneAudio;
	import game.scenes.examples.standaloneCamera.StandaloneCamera;
	import game.scenes.examples.standaloneCharacter.StandaloneCharacter;
	import game.scenes.examples.standaloneCollision.StandaloneCollision;
	import game.scenes.examples.standaloneMotion.StandaloneMotion;
	import game.scenes.examples.tiledScene.TiledScene;
	import game.scenes.examples.timelineAnimation.TimelineAnimation;
	import game.scenes.examples.waterExample.WaterExample;

	public class ExamplesEvents extends IslandEvents
	{
		public function ExamplesEvents()
		{
			super();
			super.scenes = [InputExample,BasicDialog,CardChecker,ComplexDialog,HitAreas,CharacterAnimation,CharacterParts,MovingHitAreas,TimelineAnimation,AnimationSequencing,StandaloneCamera,StandaloneCharacter,StandaloneMotion,EntitySleep,CustomCharacter,BasicPopup,TimelineAnimation,game.scenes.examples.standaloneCollision.StandaloneCollision,game.scenes.examples.characterNavigation.CharacterNavigation,game.scenes.examples.cameraControl.CameraControl,game.scenes.examples.audioExample.AudioExample,CharacterPopup,game.scenes.examples.particlesExample.ParticlesExample,SpecialAbilityExample, ItemExample,game.scenes.examples.fixedTimestepDemo.FixedTimestepDemo,game.scenes.examples.bounceMaster.BounceMaster, game.scenes.examples.bounceMaster.BounceMasterMini, game.scenes.examples.tiledScene.TiledScene, DebugExample, StandaloneAudio, GestureExample,ScenePhysics, WaterExample, CutSceneTest,SceneItems, SmartFoxHelloWorld, Projectiles, MultiplayerExample];
			scenes.push(BoatSceneExample,DynamicBoatScene,NapeCharacter,NapeBasic,NapeMagnets,NapeDynamicPlatforms);
			scenes.push(PhotoEvents);
		}
	}
}