using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleWater : MonoBehaviour
{
    private Vector3 point = new Vector3(0, 0, 0);

    private Material material;

    private float panelWidth;
    private float panelHeight;

    private void Awake()
    {
        material = GetComponent<MeshRenderer>().material;


        if (material == null)
            Debug.Log("null");

        panelWidth = transform.localScale.x * 5;
        panelHeight = transform.localScale.z * 5;

        material.SetFloat("_waveWidth", 0);
        material.SetFloat("_waveWidth2", 0);

        material.SetVector("_wavePos", new Vector4(0, 0, 0, 0));

        //material.SetFloat("_PanelWidth", panelWidth);
        //material.SetFloat("_PanelHeight", panelHeight);
    }

    private void PassWaveWidth(float time)
    {
        material.SetFloat("_waveWidth", 0);

        float t = Time.time;
    }

    private void OnCollisionEnter(Collision collision)
    {
        ContactPoint contact = collision.contacts[0];
        //碰撞点坐标 
        Vector3 pos = contact.point;
        //GetDes = pos; 
        //gameObject.layer = 0； 

        pos -= transform.position;

        //Vector2 wavePos = new Vector2(pos.x / panelWidth, pos.z / panelHeight);      

        pos.x /= panelWidth;
        pos.z /= panelHeight;

        pos.x = pos.x / 2 + 0.5f;
        pos.z = pos.z / 2 + 0.5f;

        //Debug.Log(new Vector2(pos.x, pos.z));

        material.SetVector("_wavePos", new Vector4(1 - pos.x, 1 - pos.z,panelWidth,panelHeight));

        //material.SetVector("_wavePos",new Vector2(pos.x, pos.z));
    }
}
