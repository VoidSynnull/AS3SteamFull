package game.manifest
{
	//import brfv4.BRFFace;
	
	import game.comicViewer.groups.ComicViewerPopup;
	import game.components.entity.character.part.GooglyEyes;
	import game.data.animation.entity.character.*;
	import game.data.animation.entity.character.custom.Flex;
	import game.data.animation.entity.character.custom.GumPop;
	import game.data.animation.entity.character.custom.ShootArm;
	import game.data.animation.entity.character.custom.Stinks;
	import game.data.animation.entity.character.custom.WaspFly;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.character.AddBalloon;
	import game.data.specialAbility.character.AddFollower;
	import game.data.specialAbility.character.AddMotionBlur;
	import game.data.specialAbility.character.AddPopFollower;
	import game.data.specialAbility.character.AddShoes;
	import game.data.specialAbility.character.BobbleHead;
	import game.data.specialAbility.character.CrazyJumping;
	import game.data.specialAbility.character.CreateNPC;
	import game.data.specialAbility.character.DiscThrow;
	import game.data.specialAbility.character.Dribble;
	import game.data.specialAbility.character.EngulfFlames;
	import game.data.specialAbility.character.FreezeRay;
	import game.data.specialAbility.character.GustBlow;
	import game.data.specialAbility.character.InvisiblePower;
	import game.data.specialAbility.character.IslandTransport;
	import game.data.specialAbility.character.Ketchup;
	import game.data.specialAbility.character.Legs;
	import game.data.specialAbility.character.LongShorts;
	import game.data.specialAbility.character.MovingEyes;
	import game.data.specialAbility.character.PartTimelineOnOff;
	import game.data.specialAbility.character.PartTimelineOpenClose;
	import game.data.specialAbility.character.ParticlesOnOff;
	import game.data.specialAbility.character.PlaceHazard;
	import game.data.specialAbility.character.PlaceObject;
	import game.data.specialAbility.character.PlayPopupAnim;
	import game.data.specialAbility.character.PlayPopupAnimVideo;
	import game.data.specialAbility.character.PlayPopupAnimWithPlayer;
	import game.data.specialAbility.character.Psychodelic;
	import game.data.specialAbility.character.RainAssets;
	import game.data.specialAbility.character.ScreenSwarm;
	import game.data.specialAbility.character.ShootGun;
	import game.data.specialAbility.character.ShootRay;
	import game.data.specialAbility.character.Skateboard;
	import game.data.specialAbility.character.ThoughtBubble;
	import game.data.specialAbility.character.ThrowCurd;
	import game.data.specialAbility.character.ThrowItem;
	import game.data.specialAbility.character.TimelineGun;
	import game.data.specialAbility.character.TintAllCharacters;
	import game.data.specialAbility.character.TopDownShooter;
	import game.data.specialAbility.character.TossItem;
	import game.data.specialAbility.character.TransformMultiply;
	import game.data.specialAbility.character.TurnNpcToMedusa;
	import game.data.specialAbility.character.TurnNpcToStone;
	import game.data.specialAbility.character.TwirlItem;
	import game.data.specialAbility.character.TwirlPartOfItem;
	import game.data.specialAbility.character.VortexSwirl;
	import game.data.specialAbility.character.WhoopeeCushion;
	import game.data.specialAbility.character.WingFlap;
	import game.data.specialAbility.islands.arab.AddDynamicFlames;
	import game.data.specialAbility.islands.arab.MagicCarpet;
	import game.data.specialAbility.islands.arab.ThrowMagicSand;
	import game.data.specialAbility.islands.arab.ThrowSmokeBomb;
	import game.data.specialAbility.islands.carnival.AddFlashlightEffect;
	import game.data.specialAbility.islands.carnival.CarnivalHammer;
	import game.data.specialAbility.islands.ghd.GelatinSaladBounce;
	import game.data.specialAbility.islands.ghd.RubGuano;
	import game.data.specialAbility.islands.poptropicon.HoldShield;
	import game.data.specialAbility.islands.poptropicon.Mjolnir;
	import game.data.specialAbility.islands.poptropicon.PowerGlove;
	import game.data.specialAbility.islands.poptropicon.ShootBow;
	import game.data.specialAbility.islands.survival.Fishing;
	import game.data.specialAbility.islands.survival.SetHandParts;
	import game.data.specialAbility.islands.survival.Survival2Fishing;
	import game.data.specialAbility.islands.time.SlowFall;
	import game.data.specialAbility.islands.timmy.ThrowTreat;
	import game.data.specialAbility.store.AddGum;
	import game.data.specialAbility.store.AddSnow;
	import game.data.specialAbility.store.AddStars;
	import game.data.specialAbility.store.AtomPower;
	import game.data.specialAbility.store.BirthdayHat;
	import game.data.specialAbility.store.ColdWindPower;
	import game.data.specialAbility.store.EarthKnight;
	import game.data.specialAbility.store.ElectroBaton;
	import game.data.specialAbility.store.ElectroPower;
	import game.data.specialAbility.store.EpisodicIslandPart;
	import game.data.specialAbility.store.FreezeGame;
	import game.data.specialAbility.store.GlitchPower;
	import game.data.specialAbility.store.HeatWave;
	import game.data.specialAbility.store.HypnoPowder;
	import game.data.specialAbility.store.LightningStaff;
	import game.data.specialAbility.store.MagicHat;
	import game.data.specialAbility.store.Medusa;
	import game.data.specialAbility.store.MeteorShower;
	import game.data.specialAbility.store.Midas;
	import game.data.specialAbility.store.PlaceFlare;
	import game.data.specialAbility.store.PlaceStatue;
	import game.data.specialAbility.store.PlaceUmbrella;
	import game.data.specialAbility.store.Potion;
	import game.data.specialAbility.store.SilentTreatment;
	import game.data.specialAbility.store.SillyString;
	import game.data.specialAbility.store.SneezingPowder;
	import game.data.specialAbility.store.Torch;
	import game.data.specialAbility.store.VirusLegs;
	import game.data.specialAbility.store.WhiteOut;
	import game.particles.emitter.WaterSplash;
	import game.particles.emitter.characterAnimations.Dust;
	import game.particles.emitter.specialAbility.AssetRain;
	import game.particles.emitter.specialAbility.Binary;
	import game.particles.emitter.specialAbility.Bubbles;
	import game.particles.emitter.specialAbility.CinnamonGum;
	import game.particles.emitter.specialAbility.ClassicGum;
	import game.particles.emitter.specialAbility.ClownWater;
	import game.particles.emitter.specialAbility.ColoredBomb;
	import game.particles.emitter.specialAbility.ConfettiBomb;
	import game.particles.emitter.specialAbility.DripExternalAsset;
	import game.particles.emitter.specialAbility.DropExternalAsset;
	import game.particles.emitter.specialAbility.DropExternalBitmap;
	import game.particles.emitter.specialAbility.FairyWand;
	import game.particles.emitter.specialAbility.FartCloud;
	import game.particles.emitter.specialAbility.FirefighterExtinguisher;
	import game.particles.emitter.specialAbility.GarlicBreath;
	import game.particles.emitter.specialAbility.GustBlowParticles;
	import game.particles.emitter.specialAbility.PsychadelicGum;
	import game.particles.emitter.specialAbility.ShootCloud;
	import game.particles.emitter.specialAbility.ShootSparks;
	import game.particles.emitter.specialAbility.ShootSpitballs;
	import game.particles.emitter.specialAbility.Swarm;
	import game.particles.emitter.specialAbility.VortexSwirlParticles;
	import game.particles.emitter.specialAbility.WinterGum;
	import game.scenes.arab3.shared.DivinationImpactResponse;
	import game.scenes.clubhouse.ClubhouseEvents;
	import game.scenes.custom.AutoCardVideo;
	import game.scenes.custom.CustomEvents;
	import game.scenes.custom.items.TicketContentView;
	import game.scenes.ghd.shared.MapOSphereCardView;
	import game.scenes.hub.HubEvents;
	import game.scenes.map.MapEvents;
	import game.scenes.start.StartEvents;
	import game.scenes.tutorial.TutorialEvents;
	import game.systems.actionChain.actions.ActivateSpecialOnPart;
	import game.systems.actionChain.actions.AddGlowFilterAction;
	import game.systems.actionChain.actions.AddSpecialAbilityAction;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.CameraShakeAction;
	import game.systems.actionChain.actions.ColorizeNPCAction;
	import game.systems.actionChain.actions.CreateVortexAction;
	import game.systems.actionChain.actions.EventAction;
	import game.systems.actionChain.actions.FollowAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.HideSkinAction;
	import game.systems.actionChain.actions.LoadSceneAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.MultiAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.PartParticlesAction;
	import game.systems.actionChain.actions.PartTimelineAction;
	import game.systems.actionChain.actions.ParticleEmitterAction;
	import game.systems.actionChain.actions.RemoveComponentAction;
	import game.systems.actionChain.actions.RemoveEntityAction;
	import game.systems.actionChain.actions.RemoveEventAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.RevertSkinAction;
	import game.systems.actionChain.actions.ScreenTintAction;
	import game.systems.actionChain.actions.SetAbilityActiveAction;
	import game.systems.actionChain.actions.SetAlphaAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetLookAction;
	import game.systems.actionChain.actions.SetScaleAction;
	import game.systems.actionChain.actions.SetScaleTargetAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.SetVisibleAction;
	import game.systems.actionChain.actions.ShowOverlayAnimAction;
	import game.systems.actionChain.actions.ShowPopupAction;
	import game.systems.actionChain.actions.SkinFrameAction;
	import game.systems.actionChain.actions.SkinFrameHitBoxAction;
	import game.systems.actionChain.actions.StopFollowAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.TweenAction;
	import game.systems.actionChain.actions.TweenNPCSAction;
	import game.systems.actionChain.actions.TwirlItemAction;
	import game.systems.actionChain.actions.UnlockControlAction;
	import game.systems.actionChain.actions.VariableTimelineAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.actionChain.actions.WaitCallbackAction;
	import game.systems.actionChain.actions.WaitSignalAction;
	import game.systems.actionChain.actions.ZeroMotionAction;
	import game.ui.CustomFonts;
	import game.ui.Fonts;
	import game.ui.card.CharacterContentView;
	import game.ui.card.CharacterHeadContentView;
	import game.ui.card.CreditsContentView;
	import game.ui.card.EpisodicIslandContentView;
	import game.ui.card.MovieClipContentView;
	import game.ui.card.MultiFrameContentView;
	import game.ui.card.storeCardPopups.FortuneCookie;
	import game.ui.popup.CardPopupPower;
	import game.ui.popup.ItemStorePopup;
	import game.ui.profile.ProfilePopup;
	import game.ui.settings.AccountSettings;
	
	public class DynamicallyLoadedClassManifest
	{
		public function init():Array
		{
			var events:Array = this.initEvents();
			
			// We MUST ABANDON the practice of initializing lengthy, shared arrays all on one line!
			// It's not a code-formatting holy war here, it's really a matter of Software Change Management
			// Version Control Systems maintain a file's history by comparing lines of code.
			// When all developers are continually re-writing the same line of code, the versions are perpetually in conflict.
			// Not to mention the horrible eyesore inflicted by lines which are 1000 characters wide.
			// So PLEASE! in this file, one item per line. And don't bother with sorting, just go with chronological order.
			// TODO : modify Scene Wizard.jsfl to do a better job
			var animations:Array = [
				Alerted,
				Attack,
				AttackRun,
				Angry,
				BabyCry,
				BabyIdle,
				BigStomp,
				BlockNinja,
				BodyShock,
				BottleShake,
				Bounce,
				Charge,
				Cry,
				CaneStamp,
				Celebrate,
				Crank,
				Crowbar,
				CrowbarHigh,
				DanceMoves01,
				DanceMoves01Loop,
				Disco,
				Dizzy,
				Drink,
				Drink2,
				DuckNinja,
				Eat,
				Excited,
				ExtendGlass,
				FallingNinja,
				FightStance,
				FlipObject,
				Float,
				FlyDownPan,
				Focus,
				FrontAimFire,
				Genie,
				Glide,
				GooglyEyes,
				Grief,
				Guitar,
				GuitarLoop,
				GuitarStrum,
				Gum,
				GumPop,
				Handcuff,
				Hammer,
				HitReact1,
				HitReact2,
				Hurl,
				JumpNinja,
				JumpSwordSwish,
				KeyboardTyping,
				KickBack,
				KissStart,
				Knock,
				Laugh,
				LeadSinger,
				LeprechanJig,
				Magnify,
				Nap,
				NinjaKick,
				Pickaxe,
				PickBall,
				PlaceBall,
				PlacePitcher,
				PointItem,
				PointPistol,
				PourPitcher,
				Pop,
				Pull,
				Push,
				PushHigh,
				PullPitcher,
				Proud,
				Read,
				Ride,
				RideLightCycle,
				RiflesShoot,
				RobotDance,
				RollNinja,
				RunNinja,
				RunSwordSwish,
				Salute,
				Score,
				Scratch,
				Shovel,
				Sing,
				SingLoop,
				Sit,
				SitSleepLoop,
				SkidNinja,
				Sleep,
				SleepingOnBack,
				SleepingSitUp,
				SmallHop2,
				Smash,
				Soar,
				SoarDown,
				SpidermanPoseLand,
				Spit,
				StandNinja,
				SuperSlash,
				Sword,
				SwordSwish,
				TakePhoto,
				TootsiePop,
				Tossup,
				Tremble,
				Twirl,
				TwirlPistol,
				UpperCutSlash,
				VaultNinja,
				VeilDance,
				Wag,
				Wag2,
				WalkNinja,
				WalkSwordSwish,
				WallJumpNinja,
				Wave,
				WeightLifting,
				WaveFront,
				WaspFly
			];
			
			// these are reusable/common special ability classes used for ads, store and islands (character folder)
			// store-specific and island-specific classes are in their own arrays and folders
			// if you can't find an old ability class, look in the archive folder
			// to unarchive an archived class, move it into a character, island or store folder and add it to this manifest
			var specials:Array = [
				AddBalloon,
				AddFollower,
				AddMotionBlur,
				AddPopFollower,
				AddShoes,
				AddSpecialAbilityAction,
				BobbleHead,
				CreateNPC,
				DiscThrow,
				Dribble,
				EarthKnight,
				EngulfFlames,
				FreezeRay,
				GustBlow,
				InvisiblePower,
				IslandTransport,
				Ketchup,
				Legs,
				MagicHat,
				MovingEyes,
				ParticlesOnOff,
				PartTimelineOnOff,
				PartTimelineOpenClose,
				PlaceHazard,
				PlaceObject,
				PlayPopupAnim,
				PlayPopupAnimVideo,
				PlayPopupAnimWithPlayer,
				Psychodelic,
				RainAssets,
				ScreenSwarm,
				ShootGun,
				ShootRay,
				Skateboard,
				SpecialAbility,
				ThoughtBubble,
				ThrowCurd,
				ThrowItem,
				TimelineGun,
				TintAllCharacters,
				TossItem,
				TopDownShooter,
				TransformMultiply,
				TurnNpcToStone,
				TurnNpcToMedusa,
				TwirlItem,
				TwirlPartOfItem,
				VortexSwirl,
				WhiteOut,
				WhoopeeCushion,
				WingFlap
			];
			
			// special ability classes associated with island items (islands folders)
			var specialsIsland:Array = [
				AddDynamicFlames,
				AddFlashlightEffect,
				CarnivalHammer,
				DivinationImpactResponse,
				game.data.specialAbility.islands.survival.Fishing,
				GelatinSaladBounce,
				HoldShield,
				MagicCarpet,
				Mjolnir,
				PowerGlove,
				RubGuano,
				SetHandParts,
				ShootBow,
				SlowFall,
				Survival2Fishing,
				ThrowMagicSand,
				ThrowSmokeBomb,
				ThrowTreat
			];
			
			// special ability classes associated with store items (store folder)
			var specialsStore:Array = [
				AddGum,
				AddSnow,
				AddStars,
				AtomPower,
				BirthdayHat,
				ColdWindPower,
				ElectroPower,
				ElectroBaton,
				EpisodicIslandPart,
				FreezeGame,
				GlitchPower,
				HeatWave,
				HypnoPowder,
				LightningStaff,
				Medusa,
				MeteorShower,
				Midas,
				PlaceFlare,
				PlaceStatue,
				PlaceUmbrella,
				SilentTreatment,
				SillyString,
				Potion,
				SneezingPowder,
				Torch,
				VirusLegs
			];
			
			// special ability classes associated with advertisements
			// These are limited, short-term classes that should be archived after the campaign ends
			var specialsLimited:Array = [ LongShorts,
				CrazyJumping,
				GustBlowParticles,
				VortexSwirlParticles
			];
			
			var uiViews:Array = [
				CharacterContentView,
				CharacterHeadContentView,
				CreditsContentView,
				MovieClipContentView,
				MultiFrameContentView,
				EpisodicIslandContentView,
				TicketContentView,	// TEMP :: This is used for the ticket sweepstakes and should be added via limited
				CardPopupPower,
				ComicViewerPopup,
				FortuneCookie,
				ProfilePopup,
				];
			
			var animationsCustom:Array = [Flex, ShootArm, Stinks];
			
			var emitters:Array = [
				AssetRain,
				Binary,
				Bubbles,
				ColoredBomb,
				ConfettiBomb,
				Dust,
				WaterSplash,
				DripExternalAsset,
				DropExternalAsset,
				DropExternalBitmap,
				ClassicGum,
				ClownWater,
				CinnamonGum,
				FairyWand,
				FartCloud,
				FirefighterExtinguisher,
				PsychadelicGum,
				ShootCloud,
				ShootSparks,
				ShootSpitballs,
				Swarm,
				//WhiteCloud,
				WinterGum,
				GarlicBreath];
			
			var actions:Array = [
				ActivateSpecialOnPart,
				AddGlowFilterAction,
				AnimationAction,
				AudioAction,
				CallFunctionAction,
				CameraShakeAction,
				ColorizeNPCAction,
				CreateVortexAction,
				EventAction,
				FollowAction,
				GetItemAction,
				HideSkinAction,
				LoadSceneAction,
				MoveAction,
				MultiAction,
				PanAction,
				ParticleEmitterAction,
				PartParticlesAction,
				PartTimelineAction,
				RemoveComponentAction,
				RemoveEntityAction,
				RemoveEventAction,
				RemoveItemAction,
				RevertSkinAction,
				ScreenTintAction,
				SetAbilityActiveAction,
				SetAlphaAction,
				SetDirectionAction,
				SetLookAction,
				SetScaleAction,
				SetScaleTargetAction,
				SetSkinAction,
				SetSpatialAction,
				SetVisibleAction,
				ShowOverlayAnimAction,
				ShowPopupAction,
				SkinFrameAction,
				SkinFrameHitBoxAction,
				StopFollowAction,
				TalkAction,
				TimelineAction,
				TriggerEventAction,
				TweenAction,
				TweenNPCSAction,
				TwirlItemAction,
				UnlockControlAction,
				VariableTimelineAction,
				WaitAction,
				WaitCallbackAction,
				WaitSignalAction,
				ZeroMotionAction];
			
			var popupsCustom:Array = [AutoCardVideo, AccountSettings];
			var customCardViews:Array = [MapOSphereCardView];
			
			var arClasses:Array = [];
			
			new Fonts();
			new CustomFonts();
			
			return(events);
		}
		
		/**
		 * For override, defines islands that will be compiled
		 * @return 
		 */
		protected function initEvents():Array
		{
			var events:Array = [
				MapEvents,
				StartEvents,
				TutorialEvents,
				CustomEvents,
				ClubhouseEvents,
				HubEvents];
			
			return(events);
		}
	}
}