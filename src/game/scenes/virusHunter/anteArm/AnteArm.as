package game.scenes.virusHunter.anteArm
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.components.hit.MovieClipHit;
	import game.components.timeline.Timeline;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundModifier;
	import game.managers.EntityPool;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.anteArm.components.Muscle;
	import game.scenes.virusHunter.anteArm.components.MuscleHit;
	import game.scenes.virusHunter.anteArm.popups.GymPopup;
	import game.scenes.virusHunter.anteArm.systems.AnteArmTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Ship;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.systems.SystemPriorities;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class AnteArm extends ShipScene
	{		
		public function AnteArm()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			//super.minCameraScale = .8;
			super.groupPrefix = "scenes/virusHunter/anteArm/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			setupMuscleData();
			
			_events = super.events as VirusHunterEvents;
			_pool = new EntityPool();
			
			_shipGroup = super.getGroupById( "shipGroup" ) as ShipGroup;
			_shipGroup.createSceneWeaponTargets( super._hitContainer );
	
			super.addSystem( new TimelineClipSystem() );
			super.addSystem( new TimelineControlSystem() );
			
			if( super.shellApi.checkEvent( _events.ARM_BOSS_DEFEATED ))
			{
				_expanding = false;
//				super.addSystem( new MuscleSystem( ));
			}
			
			super.addSystem( new AnteArmTargetSystem( this, _events ), SystemPriorities.checkCollisions );
			super.addSystem( new TweenSystem(), SystemPriorities.update );
			
			for( var number:int = 1; number < 6; number ++ )
			{
				if(super._hitContainer[ "bloodFlow" + number + "Art" ])
				{
					var entity:Entity = TimelineUtils.convertClip( super._hitContainer[ "bloodFlow" + number + "Art" ], this );
					entity.add( new Id( "bloodFlow" + number + "Art" ));
				}
			}
			
			setupBloodFlow();
			setupMuscles();
			
			if( !super.shellApi.checkEvent( _events.START_WORKOUT_POPUP ))
			{
				CharUtils.lockControls( shellApi.player, true, true );
				SceneUtil.lockInput( this, true );
				MotionUtils.zeroMotion( shellApi.player );
				
				SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, triggerPopup ));
			}
			
			var ship:Ship = shellApi.player.get( Ship );
			ship.damageVelocity = 100;
		}
		
		private function setupMuscleData():void
		{
			_muscles = new Vector.<Muscle>;
			
			// muscle 1
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 123.85, 644.05, 47.2, 1, 176.45, 629.95, 24.8, 1.359 )
						, new MuscleHit( 250, 810.55, 60.7, 1, 426.8, 805, 49.5, 1.464 )
						, new MuscleHit( 262.9, 1153, 117.6, 1, 447.2, 1158.3, 133.3, 1 )
						, new MuscleHit( 126.4, 1297.75, -35.1, 1, 204.75, 1299.2, -23.9, 1.494 )
						, new MuscleHit( 272.75, 981.3, 90, 1, 493.6, 993.45, 90, 1 ));
			
			_acidHits.push( new MuscleHit( 312.55, 918.35, 90, 1, 542.9, 917.1, 90, 1 )
						, new MuscleHit( 328.95, 943.6, 0, 1, 579.45, 945.1, 0, 1 )
						, new MuscleHit( 309.1, 1025.5, 0, 1, 551, 1028.05, 0, 1 ));
			
			_muscles.push( new Muscle( 1.7, "x", 2.1, _muscleHits, _acidHits ));
			
			// muscle 2
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 1050, 1224.55, -27.7, 1.131, 1015.85, 1136.85, -16.8, 1.319 )
						, new MuscleHit( 661.85, 1553.6, -55.5, 1, 591.35, 1507.8, -67.7, 1.206 )
						, new MuscleHit( 832, 1372.15, -41.6, 1, 741.9, 1279.35, -41.6, 1 ));
			
			_acidHits.push( new MuscleHit( 768.2, 1445.4, 0, 1, 686.1, 1353.9, 0, 1 )
						, new MuscleHit( 804.9, 1391.95, 0, 1, 718.45, 1285.8, 0, 1 )
						, new MuscleHit( 854, 1352.35, 0, 1, 762.85, 1252.9, 0, 1 )
						, new MuscleHit( 904.75, 1316.1, 0, 1, 813, 1209.95, 0, 1 ));
			
			_muscles.push( new Muscle( 1.8, "x", 2.5, _muscleHits, _acidHits ));
			
			// muscle 3
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 561.35, 656.1, 53.7, .809, 543.65, 672.75, 62.1, 1 )
						, new MuscleHit( 692.7, 775.9, 27.8, 1, 686.95, 873.15, 43.1, 1.377 )
						, new MuscleHit( 1069.5, 776.25, -20.9, 1, 1060.4, 908.3, -27.8, 1.215 )
						, new MuscleHit( 1268.8, 664.5, -35.8, 1, 1256.45, 720.55, -56.2, 1.233 )
						, new MuscleHit( 857.85, 812.45, 0, 1, 862.7, 942.45, 0, 1 ));
			
			_acidHits.push( new MuscleHit( 796.05, 826.8, 0, .83, 802.15, 973.05, 0, .83 )
						, new MuscleHit( 887.1, 852.6, 0, 1, 893.25, 1002.75, 0, 1 )
						, new MuscleHit( 929.8, 851, 0, 1, 937.25, 994, 0, 1 ));
			
			_muscles.push( new Muscle( 1.5, "y", 1.7, _muscleHits, _acidHits ));
			
			// muscle 4
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 706.85, 543, -18.2, 1, 671.25, 489.45, -26.9, 1.151 )
						, new MuscleHit( 1219.25, 508.5, 9, 1.1, 1276.1, 456.4, 18, 1.101 )
						, new MuscleHit( 958.35, 493.2, 0, 1, 959.15, 406.1, -2.7, 1.128 ));
			
			_acidHits.push( new MuscleHit( 838.05, 483, 0, 1, 836.05, 381, 0, 1 )
						, new MuscleHit( 947.25, 482, 0, 1, 938.25, 376.9, 0, 1 )
						, new MuscleHit( 1038.5, 442.65, 0, 1, 1035.5, 329.5, 0, 1 ));
			
			_muscles.push( new Muscle( 1.7, "y", 1.5, _muscleHits, _acidHits ));
			
			// muscle 5
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 519.45, 94.75, 40.3, .597, 542, 136.7, 52.8, .597 )
						, new MuscleHit( 635.35, 159.3, 19.4, .589, 651.15, 232.4, 26.6, .589 )
						, new MuscleHit( 932, 149.05, -23.4, .524, 929.95, 213.15, -35.6, .524 )
						, new MuscleHit( 1041.1, 88.75, -39.2, .492, 1026.45, 127.7, -49.2, .492 )
						, new MuscleHit( 785.15, 168.6, 0, 1, 791.75, 247.4, 0, .875 ));
				
			_acidHits.push( new MuscleHit( 707.9, 196.15, 0, .882, 713.9, 292.65, 0, .882 )
						, new MuscleHit( 817.2, 188.95, 0, 1.525, 824.35, 281.7, 0, 1.525 )
						, new MuscleHit( 841.2, 209.65, 0, 1, 841.2, 301.4, 0, 1 ));
				
			_muscles.push( new Muscle( 1.7, "y", 2.2, _muscleHits, _acidHits ));
			
			// muscle 6
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 1365.05, 691.9, 105.3, 1.291, 1428.15, 693.9, 99.5, 1.291 ));
				
			_acidHits.push( new MuscleHit( 1419.9, 613.65, 0, .59, 1502.65, 653.65, 0, .59 )
						, new MuscleHit( 1401.15, 690.1, 0, 1, 1479.55, 729.55, 0, 1 )
						, new MuscleHit( 1378.9, 751.5, 0, 1, 1464, 793.1, 0, 1 ));
				
			_muscles.push( new Muscle( 1.7, "x", 2.4, _muscleHits, _acidHits ));
			
			// muscle 7
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 1858.4, 461.15, -73.9, .764, 1759.05, 487.2, -64.7, .764 )
						, new MuscleHit( 1875.85, 870.3, 63.2, .455, 1781.85, 869.25, 63.2, .455 )
						, new MuscleHit( 1843, 681.05, 86.8, 1.212, 1734.85, 682.7, 86.8, 1.212 ));
				
			_acidHits.push( new MuscleHit( 1788.65, 593.5, 90, .526, 1666.45, 593.5, 90, .526 )
						, new MuscleHit( 1802, 700, 0, 1, 1684.8, 688.95, 0, 1 )
						, new MuscleHit( 1791.6, 793.5, 0, 1, 1682.8, 788.25, 0, 1 ));
			
			_muscles.push( new Muscle( 1.5, "x", 1.9, _muscleHits, _acidHits ));
			
			// muscle 8
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 1322.25, 975, 52.4, .716, 1441.4, 951.3, 32.2, .716 )
						, new MuscleHit( 1468.45, 1323.85, 79, .74, 1639.75, 1302.75, 89.2, 1.058 )
						, new MuscleHit( 1407.15, 1142.45, 68.8, 1.107, 1577.15, 1091.7, 56.8, 1.107 ));
							
			_acidHits.push( new MuscleHit( 1391.2, 1073.75, 90, .41, 1565.45, 1024.65, 90, .41 )
						, new MuscleHit( 1416.05, 1124.35, 0, 1, 1616.35, 1068.75, 0, 1 )
						, new MuscleHit( 1440.1, 1206.6, 0, 1, 1633.4, 1154.25, 0, 1 ));
			
			_muscles.push( new Muscle( 2.5, "x", 2.45, _muscleHits, _acidHits ));
			
			// muscle 9
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 1812.2, 917.75, 56.7, .363, 1769.1, 916.5, 73.4, .43 )
						, new MuscleHit( 2081.7, 1129.85, -160.3, .677, 2059.65, 1137.6, -166, .721 )
						, new MuscleHit( 1911.35, 1015.8, 41.4, 1.096, 1878.3, 1035.5, 41.4, 1.187 ));
				
			_acidHits.push( new MuscleHit( 1853.45, 958, 0, .45, 1821.4, 986.5, 0, .45 )
						, new MuscleHit( 1893.15, 1002.8, 0, 1, 1862.3, 1026.85, 0, 1 )
						, new MuscleHit( 1932.15, 1023.55, 0, 1, 1898.1, 1055.75, 0, 1 )
						, new MuscleHit( 1956.75, 1061.75, 0, 1, 1922.7, 1095.1, 0, 1 )
						, new MuscleHit( 2003.8, 1088.75, 0, 1, 1976.15, 1118.8, 0, 1 ));
			
			_muscles.push( new Muscle( 1.4, "x", 1.5, _muscleHits, _acidHits ));
			
			// muscle 10
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 2210.5, 1111.5, -14.9, .695, 2254.55, 1170.25, -8.9, .685 )
						, new MuscleHit( 2393.05, 1094.9, 2.5, .652, 2379, 1150.35, 2.5, .652 )
						, new MuscleHit( 2821.7, 1057.4, -20.1, .535, 2846.8, 1074.8, -27.6, .709 )
						, new MuscleHit( 2629.5, 1078, -7.8, 1.373, 2621.5, 1130.2, -12.7, 1.373 ));
				
			_acidHits.push( new MuscleHit( 2534.95, 1110.45, 0, 1, 2530.35, 1182.55, 0, 1 )
						, new MuscleHit( 2658.05, 1098.75, 0, 1, 2659.05, 1164.85, 0, 1 )
						, new MuscleHit( 2741.05, 1075.95, 0, 1, 2740.05, 1129.25, 0, 1 ));
			
			_muscles.push( new Muscle( 1.7, "y", 2.3, _muscleHits, _acidHits ));
			
			// muscle 11
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 2119.05, 399.55, 74.7, .884, 2236.8, 366.7, 66.4, .884 )
						, new MuscleHit( 2082.95, 877.75, -67.1, .84, 2165.75, 906.45, -53.7, 1.037 )
						, new MuscleHit( 2133.85, 642.65, 92.2, 1.39, 2273.3, 634.55, 92.2, 1.39 ));
				
			_acidHits.push( new MuscleHit( 2192.35, 511.85, 90, 1.199, 2380.05, 511.85, 90, 1.199 )
						, new MuscleHit( 2154.25, 597.6, 0, 1, 2304.15, 596.85, 0, 1 )
						, new MuscleHit( 2173.7, 754.1, 0, 1, 2342.55, 749.15, 0, 1 ));
			
			_muscles.push( new Muscle( 1.7, "x", 2.2, _muscleHits, _acidHits ));
			
			// muscle 12
			_muscleHits = new Vector.<MuscleHit>;
			_acidHits = new Vector.<MuscleHit>;
			
			_muscleHits.push( new MuscleHit( 3529.35, 760.95, -5.9, 1, 3518.55, 794.75, -19.9, 1 )
						, new MuscleHit( 3175.5, 771.7, -2.2, .517, 3180.9, 884.15, -10.7, .517 )
						, new MuscleHit( 2881.15, 771.65, 2.6, .433, 2876.6, 901.55, 2.6, .433 )
						, new MuscleHit( 2546.45, 738.8, 12.2, 1.11, 2531, 786.75, 29.9, 1.275 )
						, new MuscleHit( 2488.3, 694.5, -12.4, .721, 2597.9, 571.8, -31.4, 1.1 )
						, new MuscleHit( 2866.6, 679.9, 3, .681, 2864.6, 481.65, 3, .68 )
						, new MuscleHit( 3372.85, 715.75, 7.4, 1.879, 3384.05, 560.65, 17.7, 2.041 )
						, new MuscleHit( 2390.25, 707.7, -90, 1, 2404.3, 674.5, -90, 2.809 )
						, new MuscleHit( 3317.25, 761.9, -4.2, 1, 3307.2, 853.15, -15.6, 1 )
						, new MuscleHit( 3029.8, 768.5, 0, 1, 3029.8, 893.7, 0, 1 )
						, new MuscleHit( 2755.45, 755.8, 6, 1, 2747.45, 871.7, 12.7, 1 )
						, new MuscleHit( 2680.35, 687.95, -2.2, 1.105, 2698.4, 501.65, -12.2, 1.105 )
						, new MuscleHit( 3042.25, 695.4, 1.9, .878, 3052.25, 493.15, 1.9, .878 ));
				
			_acidHits.push( new MuscleHit( 3252.25, 788.55, 0, .294, 3252.25, 940.7, 0, .294 )
						, new MuscleHit( 2956.5, 798.9, 0, .904, 2961.05, 960.5, 0, .904 )
						, new MuscleHit( 2698, 774.25, 0, .641, 2696.8, 920.2, 0, .641 )
						, new MuscleHit( 2614.55, 650.9, 0, .887, 2624.55, 459.4, 0, .887 )
						, new MuscleHit( 3005.2, 667.35, 0, .432, 3021.25, 439, 0, .432 )
						, new MuscleHit( 3086.55, 669.75, 0, 1, 3106.55, 447.45, 0, 1 )
						, new MuscleHit( 3323.2, 795.5, 0, 1, 3309.2, 897.75, 0, 1 )
						, new MuscleHit( 3026.8, 802.55, 0, 1, 3030.8, 949, 0, 1 )
						, new MuscleHit( 3102.9, 809.55, 0, 1, 3098.9, 965.8, 0, 1 )
						, new MuscleHit( 2756.45, 785.75, 0, 1, 2749.1, 923.95, 0, 1 )
						, new MuscleHit( 2811.45, 795.5, 0, 1, 2803.45, 948.5, 0, 1 )
						, new MuscleHit( 2687.75, 657.9, 0, 1, 2710.35, 445.2, 0, 1 )
						, new MuscleHit( 2749.6, 640.3, 0, 1, 2751.7, 411.35, 0, 1 ));
			
			_muscles.push( new Muscle( 3, "y", 3.1, _muscleHits, _acidHits ));
		}
		
		/*********************************************************************************
		 * POPUP HANDLER
		 */
		private function triggerPopup():void
		{
			var popup:GymPopup = super.addChildGroup( new GymPopup( super.overlayContainer )) as GymPopup;
			popup.closeSignal.add( closePopup );
			popup.id = "gymPopup";
		}
		
		private function closePopup():void
		{
			var popup:Popup = super.getGroupById( "gymPopup" ) as Popup;
			popup.close();	
			CharUtils.lockControls( shellApi.player, false, false );
			SceneUtil.lockInput( this, false );
			super.shellApi.completeEvent( _events.START_WORKOUT_POPUP );
		}
		
		/*********************************************************************************
		 * SETUP BLOODFLOW
		 */
		private function setupBloodFlow():void
		{
			var entity:Entity;
			var timeline:Timeline;
			var damageTarget:DamageTarget;
			
			_shipGroup.createOffscreenSpawn( EnemyType.RED_BLOOD_CELL, 4, .5, 40, 140, 5 );
			
			for( var number:int = 1; number < 6; number ++ )
			{
				if( !super.shellApi.checkEvent( _events.CLOGGED_UPPER_ARM_CUT_ + number ))
				{
					entity = super.getEntityById( "bloodFlow" + number + "Target" );
					_shipGroup.addSpawn(  entity, EnemyType.RED_BLOOD_CELL, 6, new Point(80, 40), new Point(-30, -40), new Point(40, 30), .5 ); 
					damageTarget = entity.get( DamageTarget );
					damageTarget.reactToInvulnerableWeapons = false;
				}
				else
				{
					super.removeEntity( super.getEntityById( "bloodFlow" + number + "Target" ));
					super.removeEntity( super.getEntityById( "bloodFlow" + number ));
					timeline = super.getEntityById( "bloodFlow" + number  + "Art" ).get( Timeline );
					timeline.gotoAndPlay( "end" );
				}
			}
		}
		
		/*********************************************************************************
		 * SETUP MUSCLES
		 */
		private function setupMuscles():void
		{
			var muscleEntity:Entity
			var entity:Entity;
			var spatial:Spatial;
			var display:Display;
			
			var muscle:Muscle;
			var hit:MuscleHit;
			var timeline:Timeline;
			
			var creator:HitCreator = new HitCreator();
			
			var hitCount:Number;
			var mCHit:MovieClipHit;
			
			var hazard:Hazard;
			var acidCount:Number;
			var loop:int;
			
			// loop through the 13 muscles in the scene
			// 13
			for( var number:int = 1; number < _muscles.length + 1; number ++ )
			{
				muscleEntity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "muscleArt" + number ]);
				muscle = _muscles[ number - 1 ]
				muscleEntity.add( muscle ).add( new Tween());
				
				TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( muscleEntity )), this, muscleEntity );
				
				timeline = muscleEntity.get( Timeline );
				Sleep( muscleEntity.get( Sleep )).ignoreOffscreenSleep = true;
				
				// add audio component 
				muscleEntity.add(new Audio());
				muscleEntity.add(new AudioRange(600, 0.01, 1));
								
				for( loop = 0; loop < muscle.acidHits.length; loop ++ )
				{
					entity = EntityUtils.createMovingEntity( this, super._hitContainer[ "muscle" + number  + "acid" + ( loop + 1 )]);
					display = entity.get( Display );
					display.visible = false;
					
					spatial = entity.get( Spatial );
					mCHit = new MovieClipHit( EnemyType.ENEMY_HIT, "ship" );
					mCHit.shapeHit = true;
					mCHit.hitDisplay = MovieClip( display.displayObject );
					entity.add( mCHit  );
					
					hazard = new Hazard( 4, 4 );
					hazard.damage = .2;
					hazard.coolDown = 10;
					entity.add( hazard ).add( new Tween());
					
					entity.add( muscle.acidHits[ loop ]);
					muscle.acid.push( entity );					
				}
				
				for( loop = 0; loop < muscle.muscleHits.length; loop ++ )
				{
					entity = EntityUtils.createMovingEntity( this, super._hitContainer[ "muscle" + number + "hit" + ( loop + 1 )]);
					display = entity.get( Display );
					display.visible = false;
					
					creator.makeHit( entity, HitType.RADIAL );
					
					entity.add( muscle.muscleHits[ loop ]).add( new Tween());
					muscle.hits.push( entity );
				}

				muscleEntity.add( muscle );
				
				if( _expanding )
				{
					expandTween( muscleEntity );
				}
			}
			
			entity = EntityUtils.createMovingEntity( this, super._hitContainer[ "extraAcid" ]);
			
			mCHit = new MovieClipHit( EnemyType.ENEMY_HIT, "ship" );
			mCHit.shapeHit = true;
			mCHit.hitDisplay = MovieClip( EntityUtils.getDisplayObject( entity ));
			entity.add( mCHit );
			Display( entity.get( Display )).visible = false;
			
			hazard = new Hazard( 4, 4 );
			hazard.damage = 0.2;
			hazard.coolDown = 10;
			entity.add( hazard );
		}
		
		/*********************************************************************************
		 * UTILS
		 */
		
		private function expandTween( muscleEntity:Entity ):void
		{
			var muscle:Muscle = muscleEntity.get( Muscle );
			var tween:Tween = muscleEntity.get( Tween );
			var spatial:Spatial = muscleEntity.get( Spatial );
			
			var number:int; 
			var entity:Entity;
			var hit:MuscleHit;
			
			var sound:String = MUSCLE_EXPAND;
			var audio:Audio = muscleEntity.get(Audio);
			
			audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
			
			if( muscle.axis == "x" )
			{
				tween.to( spatial, muscle.time, { scaleX : muscle.maxExpansion, onComplete : Command.create( constrictTween, muscleEntity )});
			}
			else
			{
				tween.to( spatial, muscle.time, { scaleY : muscle.maxExpansion, onComplete : Command.create( constrictTween, muscleEntity )});
			}
			
			// acid
			for( number = 0; number < muscle.acid.length; number ++ )
			{
				entity = muscle.acid[ number ];
				hit = entity.get( MuscleHit );
				spatial = entity.get( Spatial );
				
				tween = entity.get( Tween );
				tween.to( spatial, muscle.time, { x : hit.endX, y : hit.endY });
			}
			
			// muscle
			for( number = 0; number < muscle.hits.length; number ++ )
			{
				entity = muscle.hits[ number ];
				hit = entity.get( MuscleHit );
				spatial = entity.get( Spatial );
				
				tween = entity.get( Tween );
				tween.to( spatial, muscle.time, { scaleX : hit.endScale, x : hit.endX, y : hit.endY, rotation : hit.endRotation });
			}
		}
		
		private function constrictTween( muscleEntity:Entity ):void
		{
			var muscle:Muscle = muscleEntity.get( Muscle );
			var tween:Tween = muscleEntity.get( Tween );
			var spatial:Spatial = muscleEntity.get( Spatial );
			
			var entity:Entity;
			var number:int;
			var hit:MuscleHit;
			
			var sound:String = MUSCLE_CONTRACT;
			var audio:Audio = muscleEntity.get(Audio);
			
			audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
			
			if( muscle.axis == "x" )
			{
				tween.to( spatial, muscle.time, { scaleX : 1, onComplete : Command.create( expandTween, muscleEntity )});
			}
			else
			{
				tween.to( spatial, muscle.time, { scaleY : 1, onComplete : Command.create( expandTween, muscleEntity )});
			}
			
			// acid
			for( number = 0; number < muscle.acid.length; number ++ )
			{
				entity = muscle.acid[ number ];
				hit = entity.get( MuscleHit );
				spatial = entity.get( Spatial );
				
				tween = entity.get( Tween );
				tween.to( spatial, muscle.time, { x : hit.startX, y : hit.startY });
			}
			
			// muscle
			for( number = 0; number < muscle.hits.length; number ++ )
			{
				entity = muscle.hits[ number ];
				hit = entity.get( MuscleHit );
				spatial = entity.get( Spatial );
				
				tween = entity.get( Tween );
				tween.to( spatial, muscle.time, { scaleX : hit.startScale, rotation : hit.startRotation, x : hit.startX, y : hit.startY });
			}
		}
		
		private function removeTarget( id:String ):String
		{
			var index:Number = id.indexOf( "Target" );
			
			return( id.slice( 0, index ));
		}
		
		static private const MUSCLE_EXPAND:String = "contract_expand_muscle_02.mp3";
		static private const MUSCLE_CONTRACT:String = "contract_expand_muscle_01.mp3";
		
		private var _muscles:Vector.<Muscle>;
		private var _muscleHits:Vector.<MuscleHit>;
		private var _acidHits:Vector.<MuscleHit>;
		
		private var _expanding:Boolean = true;
		private var _events:VirusHunterEvents;
		private var _pool:EntityPool;
		private var _shipGroup:ShipGroup;
	}
}
