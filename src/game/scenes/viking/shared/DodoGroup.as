package game.scenes.viking.shared
{
	import ash.core.Entity;
	
	import engine.group.Scene;
	
	import game.components.hit.Hazard;
	import game.components.motion.TargetEntity;
	import game.scenes.viking.shared.dodoCluster.DodoCluster;
	import game.scenes.viking.shared.dodoCluster.DodoClusterSystem;
	import game.util.CharUtils;
	import game.util.SkinUtils;

	public class DodoGroup
	{
		public function DodoGroup()
		{
			
		}
		
		public function clusterAllDodos(scene:Scene, leader:Entity, offset:Number = 100, offsetChangeTime:Number = 0.5, openMouth:Boolean = false):void
		{
			for(var index:int = 1; scene.getEntityById("dodo" + index); ++index)
			{
				var dodo:Entity = scene.getEntityById("dodo" + index);
				
				this.clusterDodo(scene, dodo, leader, offset, offsetChangeTime, openMouth);
			}
		}
		
		public function clusterDodo(scene:Scene, dodo:Entity, leader:Entity, offset:Number = 100, offsetChangeTime:Number = 0.5, openMouth:Boolean = false):void
		{
			if(!scene.getSystem(DodoClusterSystem))
			{
				scene.addSystem(new DodoClusterSystem());
			}
			
			CharUtils.followEntity(dodo, leader);
			
			if(openMouth)
			{
				SkinUtils.setSkinPart(dodo, SkinUtils.FACIAL, "comic_dodo2");
				//SkinUtils.setEyeStates(dodo, EyeSystem.MEAN, null, true);
			}
			else
			{
				SkinUtils.setSkinPart(dodo, SkinUtils.FACIAL, "comic_dodo");
			}
			
			
			dodo.remove(Hazard);
			
			var target:TargetEntity = dodo.get(TargetEntity);
			target.minTargetDelta.setTo(0, 25);
			
			var cluster:DodoCluster = dodo.get(DodoCluster);
			if(!cluster)
			{
				cluster = new DodoCluster();
				dodo.add(cluster);
			}
			cluster.offsetChangeTime 	= offsetChangeTime;
			cluster.offset 				= offset;
		}
	}
}