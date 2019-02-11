using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleWater : MonoBehaviour
{
    private Vector3 point = new Vector3(0, 0, 0);

    private Material material;

    private float panelWidth;
    private float panelHeight;

    private float currentTime = -1;
    private bool isCollision = false;

    private void Awake()
    {
        material = GetComponent<MeshRenderer>().material;


        if (material == null)
            Debug.Log("material is null!");

        panelWidth = transform.localScale.x * 5;
        panelHeight = transform.localScale.z * 5;

        material.SetFloat("_StartWaveWidth", 0);
        material.SetFloat("_EndWaveWidth", 0);

        material.SetVector("_wavePos", new Vector4(0, 0, 0, 0));
    } 

    private void OnCollisionEnter(Collision collision)
    {
        ContactPoint contact = collision.contacts[0];
        //碰撞点坐标 
        Vector3 pos = contact.point; 

        pos -= transform.position;

        pos.x /= panelWidth;
        pos.z /= panelHeight;

        pos.x = pos.x / 2 + 0.5f;
        pos.z = pos.z / 2 + 0.5f;

        isCollision = true;

        StartCoroutine(ChangeWaveWidth("_StartWaveWidth", 0.8f,true));

        material.SetVector("_wavePos", new Vector4(1 - pos.x, 1 - pos.z, panelWidth, panelHeight));
    }

    private void StartWave(int index,Vector4 wavePos)
    {

    }

    private IEnumerator ChangeWaveWidth(string name, float time, bool isStartWaveWidth)
    {
        for (int i = 0; i < time * 50; i++)
        {
            material.SetFloat(name, 0.1f * i / (time * 50));
            if(Mathf.Abs(i - time * 25) <= 0.05f)
            {
                if (isStartWaveWidth)
                    StartCoroutine(ChangeWaveWidth("_EndWaveWidth", 1f, false));
            }
            yield return new WaitForSeconds(0.02f);
        }
    }
}
